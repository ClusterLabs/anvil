import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

const MAP_TO_MEMBERSHIP_JOB_PARAMS_BUILDER: Record<
  MembershipTask,
  BuildMembershipJobParamsFunction
> = {
  join: async (uuid, { isActiveMember } = {}) => {
    // Host is already a cluster member
    if (isActiveMember) return undefined;

    const rows: [[number]] = await query(
      `SELECT
          CASE
            WHEN host_status = 'online'
              THEN CAST('1' AS BOOLEAN)
            ELSE CAST('0' AS BOOLEAN)
          END
        FROM hosts WHERE host_uuid = '${uuid}';`,
    );

    assert.ok(rows.length, 'No entry found');

    const [[isOnline]] = rows;

    return isOnline
      ? {
          job_command: SERVER_PATHS.usr.sbin['anvil-safe-start'].self,
          job_description: 'job_0522',
          job_host_uuid: uuid,
          job_name: 'set_membership::join',
          job_title: 'job_0521',
        }
      : undefined;
  },
  leave: async (uuid, { isActiveMember } = {}) =>
    isActiveMember
      ? {
          job_command: SERVER_PATHS.usr.sbin['anvil-safe-stop'].self,
          job_description: 'job_0524',
          job_host_uuid: uuid,
          job_name: 'set_membership::leave',
          job_title: 'job_0523',
        }
      : undefined,
};

export const buildMembershipHandler: (
  task: MembershipTask,
) => RequestHandler<{ uuid: string }> = (task) => async (request, response) => {
  const {
    params: { uuid },
  } = request;

  const hostUuid = sanitize(uuid, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_UUID.test(hostUuid),
      `Param UUID must be a valid UUIDv4; got: [${hostUuid}]`,
    );
  } catch (error) {
    perr(
      `Failed to assert value when changing host membership; CAUSE: ${error}`,
    );

    return response.status(500).send();
  }

  let rows: [
    [
      hostInCcm: NumberBoolean,
      hostCrmdMember: NumberBoolean,
      hostClusterMember: NumberBoolean,
    ],
  ];

  try {
    rows = await query(
      `SELECT
          scan_cluster_node_in_ccm,
          scan_cluster_node_crmd_member,
          scan_cluster_node_cluster_member
        FROM scan_cluster_nodes
        WHERE scan_cluster_node_host_uuid = '${hostUuid}';`,
    );

    assert.ok(rows.length, `No entry found`);
  } catch (error) {
    perr(`Failed to get cluster status of host ${hostUuid}; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const isActiveMember = rows[0].every((stage) => Boolean(stage));

  try {
    const restParams = await MAP_TO_MEMBERSHIP_JOB_PARAMS_BUILDER[task](
      hostUuid,
      {
        isActiveMember,
      },
    );

    if (restParams) {
      await job({ file: __filename, ...restParams });
    }
  } catch (error) {
    perr(
      `Failed to initiate ${task} cluster for host ${hostUuid}; CAUSE: ${error}`,
    );

    return response.status(500).send();
  }

  return response.status(204).send();
};
