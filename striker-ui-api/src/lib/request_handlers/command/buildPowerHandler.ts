import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, LOCAL, REP_UUID, SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

/**
 * Notes on power functions:
 * * poweroff, reboot targets the striker this express app operates on
 * * start, stop targets subnode or DR host
 */
const MAP_TO_POWER_JOB_PARAMS_BUILDER: Record<
  PowerTask,
  BuildPowerJobParamsFunction
> = {
  poweroff: () => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --poweroff -y`,
    job_description: 'job_0008',
    job_name: 'poweroff::system',
    job_title: 'job_0010',
  }),
  reboot: () => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --reboot -y`,
    job_description: 'job_0006',
    job_name: 'reboot::system',
    job_title: 'job_0009',
  }),
  start: ({ uuid } = {}) => ({
    job_command: `${SERVER_PATHS.usr.sbin['striker-boot-machine'].self} --host '${uuid}'`,
    job_description: 'job_0340',
    job_name: `set_power::on`,
    job_title: 'job_0338',
  }),
  startserver: ({ runOn, uuid } = {}) => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-boot-server'].self}`,
    job_data: `server-uuid=${uuid}`,
    job_description: 'job_0352',
    job_host_uuid: runOn,
    job_name: 'set_power::server::on',
    job_title: 'job_0350',
  }),
  stop: ({ isStopServers, uuid, runOn = uuid } = {}) => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-safe-stop'].self} --power-off${
      isStopServers ? ' --stop-servers' : ''
    }`,
    job_description: 'job_0341',
    job_host_uuid: runOn,
    job_name: 'set_power::off',
    job_title: 'job_0339',
  }),
  stopserver: ({ force, runOn, uuid } = {}) => {
    let command = SERVER_PATHS.usr.sbin['anvil-shutdown-server'].self;

    if (force) {
      command += ' --immediate';
    }

    return {
      job_command: command,
      job_data: `server-uuid=${uuid}`,
      job_description: 'job_0353',
      job_host_uuid: runOn,
      job_name: 'set_power::server::off',
      job_title: 'job_0351',
    };
  },
};

const queuePowerJob = async (
  task: PowerTask,
  options?: BuildPowerJobParamsOptions,
) => {
  const params: JobParams = {
    file: __filename,

    ...MAP_TO_POWER_JOB_PARAMS_BUILDER[task](options),
  };

  return await job(params);
};

export const buildPowerHandler: (
  task: PowerTask,
  options?: { getJobHostUuid?: (uuid?: string) => Promise<string | undefined> },
) => RequestHandler<{ uuid?: string }> =
  (task, { getJobHostUuid } = {}) =>
  async (request, response) => {
    const {
      params: { uuid },
      query: { force: rForce },
    } = request;

    const force = sanitize(rForce, 'boolean');

    try {
      if (uuid) {
        assert(
          REP_UUID.test(uuid),
          `Param UUID must be a valid UUIDv4; got [${uuid}]`,
        );
      }
    } catch (error) {
      perr(`Failed to ${task}; CAUSE: ${error}`);

      return response.status(400).send();
    }

    try {
      const runOn = await getJobHostUuid?.call(null, uuid);

      await queuePowerJob(task, { force, runOn, uuid });
    } catch (error) {
      perr(`Failed to ${task} ${uuid ?? LOCAL}; CAUSE: ${error}`);

      return response.status(500).send();
    }

    response.status(204).send();
  };

export const buildAnPowerHandler: (
  task: Extract<PowerTask, 'start' | 'stop'>,
) => RequestHandler<{ uuid: string }> = (task) => async (request, response) => {
  const {
    params: { uuid },
  } = request;

  const anUuid = sanitize(uuid, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_UUID.test(anUuid),
      `Param UUID must be a valid UUIDv4; got: [${anUuid}]`,
    );
  } catch (error) {
    perr(`Failed to assert value during power operation on anvil subnode`);

    return response.status(400).send();
  }

  let rows: [[node1Uuid: string, node2Uuid: string]];

  try {
    rows = await query(
      `SELECT anvil_node1_host_uuid, anvil_node2_host_uuid
        FROM anvils WHERE anvil_uuid = '${anUuid}';`,
    );

    assert.ok(rows.length, 'No entry found');
  } catch (error) {
    perr(`Failed to get anvil subnodes' UUID; CAUSE: ${error}`);

    return response.status(500).send();
  }

  for (const hostUuid of rows[0]) {
    try {
      await queuePowerJob(task, { isStopServers: true, uuid: hostUuid });
    } catch (error) {
      perr(`Failed to ${task} host ${hostUuid}; CAUSE: ${error}`);

      return response.status(500).send();
    }
  }

  return response.status(204).send();
};

export const buildServerPowerHandler: (
  task: Extract<PowerTask, 'startserver' | 'stopserver'>,
) => RequestHandler<{ uuid: string }> = (task) =>
  buildPowerHandler(task, {
    getJobHostUuid: async (uuid) => {
      if (!uuid) return;

      let serverHostUuid: string | undefined;

      try {
        // When the server host uuid is null, fall back to the first subnode of
        // the node that owns the server.
        const rows = await query<[[null | string]]>(
          `SELECT
              COALESCE(a.server_host_uuid, b.anvil_node1_host_uuid)
            FROM servers AS a
            LEFT JOIN anvils AS b
              ON a.server_anvil_uuid = b.anvil_uuid
            WHERE server_state != '${DELETED}'
              AND server_uuid = '${uuid}';`,
        );

        assert.ok(rows.length, `No entry found`);

        const [[hostUuid]] = rows;

        if (hostUuid) {
          serverHostUuid = hostUuid;
        }
      } catch (error) {
        throw new Error(`Failed to get server host; CAUSE: ${error}`);
      }

      return serverHostUuid;
    },
  });
