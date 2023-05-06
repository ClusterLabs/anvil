import assert from 'assert';
import { RequestHandler } from 'express';

import { LOCAL, REP_UUID, SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr } from '../../shell';

/**
 * Notes on power functions:
 * * poweroff, reboot targets the striker this express app operates on
 * * start, stop targets subnode or DR host
 */
const MANAGE_HOST_POWER_JOB_PARAMS: Record<
  PowerTask,
  BuildPowerJobParamsFunction
> = {
  poweroff: () => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --poweroff -y`,
    job_name: 'poweroff::system',
    job_title: 'job_0010',
    job_description: 'job_0008',
  }),
  reboot: () => ({
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --reboot -y`,
    job_name: 'reboot::system',
    job_title: 'job_0009',
    job_description: 'job_0006',
  }),
  start: ({ uuid } = {}) => ({
    job_command: `${SERVER_PATHS.usr.sbin['striker-boot-machine'].self} --host-uuid '${uuid}'`,
    job_description: 'job_0335',
    job_name: `set_power::on`,
    job_title: 'job_0334',
  }),
  stop: ({ isStopServers, uuid } = {}) => ({
    job_command: `${
      SERVER_PATHS.usr.sbin['anvil-safe-stop'].self
    } --power-off ${isStopServers ? '--stop-servers' : ''}`,
    job_description: 'job_0333',
    job_host_uuid: uuid,
    job_name: 'set_power::off',
    job_title: 'job_0332',
  }),
};

const queuePowerJob = async (
  task: PowerTask,
  options?: BuildPowerJobParamsOptions,
) => {
  const subParams: JobParams = {
    file: __filename,

    ...MANAGE_HOST_POWER_JOB_PARAMS[task](options),
  };

  return await job(subParams);
};

export const buildPowerHandler: (
  task: PowerTask,
) => RequestHandler<{ uuid?: string }> =
  (task) => async (request, response) => {
    const {
      params: { uuid },
    } = request;

    try {
      if (uuid) {
        assert(
          REP_UUID.test(uuid),
          `Param UUID must be a valid UUIDv4; got [${uuid}]`,
        );
      }
    } catch (error) {
      stderr(`Failed to ${task} host; CAUSE: ${error}`);

      return response.status(400).send();
    }

    try {
      await queuePowerJob(task, { uuid });
    } catch (error) {
      stderr(`Failed to ${task} host ${uuid ?? LOCAL}; CAUSE: ${error}`);

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
    stderr(`Failed to assert value during power operation on anvil subnode`);

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
    stderr(`Failed to get anvil subnodes' UUID; CAUSE: ${error}`);

    return response.status(500).send();
  }

  for (const hostUuid of rows[0]) {
    try {
      await queuePowerJob(task, { isStopServers: true, uuid: hostUuid });
    } catch (error) {
      stderr(`Failed to ${task} host ${hostUuid}; CAUSE: ${error}`);

      return response.status(500).send();
    }
  }

  return response.status(204).send();
};
