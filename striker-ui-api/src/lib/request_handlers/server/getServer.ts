import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { poutvar } from '../../shell';

export const getServer = buildGetRequestHandler((request, hooks) => {
  const { anvilUUIDs } = request.query;

  const condAnvilUUIDs = join(sanitize(anvilUUIDs, 'string[]'), {
    beforeReturn: (toReturn) =>
      toReturn ? `AND a.server_anvil_uuid IN (${toReturn})` : '',
    elementWrapper: "'",
    separator: ', ',
  });

  poutvar({ condAnvilUUIDs });

  const sql = `
    SELECT
      a.server_uuid,
      a.server_name,
      a.server_state,
      a.anvil_uuid,
      a.anvil_name,
      a.anvil_description,
      a.host_uuid,
      a.host_name,
      a.host_type,
      d.job_uuid,
      d.job_progress,
      d.job_on_peer,
      d.server_name,
      d.host_uuid,
      d.host_name,
      d.host_type,
      d.anvil_uuid,
      d.anvil_name,
      d.anvil_description
    FROM (
        SELECT
          a1.server_uuid,
          a1.server_name,
          a1.server_state,
          a2.anvil_uuid,
          a2.anvil_name,
          a2.anvil_description,
          a3.host_uuid,
          a3.host_name,
          a3.host_type
        FROM servers AS a1
        JOIN anvils AS a2
          ON a2.anvil_uuid = a1.server_anvil_uuid
        LEFT JOIN hosts AS a3
          ON a3.host_uuid = a1.server_host_uuid
        WHERE a1.server_state != '${DELETED}'
          ${condAnvilUUIDs}
        ORDER BY a1.server_name ASC
      ) AS a
    FULL JOIN (
        SELECT
          d1.job_uuid,
          d1.job_progress,
          CASE
            WHEN d1.job_data LIKE '%peer_mode=true%'
              THEN 1
            ELSE 0
          END AS job_on_peer,
          SUBSTRING(d1.job_data, 'server_name=([^\\n]*)') AS server_name,
          d2.host_uuid,
          d2.host_name,
          d2.host_type,
          d3.anvil_uuid,
          d3.anvil_name,
          d3.anvil_description
        FROM jobs AS d1
        JOIN hosts AS d2
          ON d2.host_uuid = d1.job_host_uuid
        JOIN anvils AS d3
          ON d2.host_uuid IN (
            d3.anvil_node1_host_uuid,
            d3.anvil_node2_host_uuid
          )
        WHERE d1.job_command LIKE '%anvil-provision-server%'
          ${condAnvilUUIDs}
        ORDER BY
          server_name ASC,
          job_on_peer ASC
      ) AS d
      ON d.server_name = a.server_name
    ;`;

  hooks.afterQueryReturn = buildQueryResultReducer<ServerOverviewList>(
    (previous, row) => {
      const [
        serverUuid,
        serverName,
        serverState,
        anvilUuid,
        anvilName,
        anvilDescription,
        hostUuid,
        hostName,
        hostType,
        jobUuid,
        jobProgress,
        jobOnPeer,
        jobServerName,
        jobHostUuid,
        jobHostName,
        jobHostType,
        jobAnvilUuid,
        jobAnvilName,
        jobAnvilDescription,
      ] = row;

      if (serverUuid) {
        let host: ServerOverviewHost | undefined;

        if (hostUuid) {
          host = {
            name: hostName,
            short: getShortHostName(hostName),
            type: hostType,
            uuid: hostUuid,
          };
        }

        previous[serverUuid] = {
          anvil: {
            description: anvilDescription,
            name: anvilName,
            uuid: anvilUuid,
          },
          host,
          name: serverName,
          state: serverState,
          uuid: serverUuid,
        };
      } else if (jobUuid) {
        if (!previous[jobServerName]) {
          previous[jobServerName] = {
            anvil: {
              description: jobAnvilDescription,
              name: jobAnvilName,
              uuid: jobAnvilUuid,
            },
            host: {
              name: jobHostName,
              short: getShortHostName(jobHostName),
              type: jobHostType,
              uuid: jobHostUuid,
            },
            name: jobServerName,
            state: 'pending',
            uuid: jobUuid,
          };
        }

        const { [jobServerName]: server } = previous;

        if (!server.jobs) {
          server.jobs = {};
        }

        server.jobs[jobUuid] = {
          host: {
            name: jobHostName,
            short: getShortHostName(jobHostName),
            type: jobHostType,
            uuid: jobHostUuid,
          },
          peer: Number(jobOnPeer) === 1,
          progress: Number(jobProgress),
          uuid: jobUuid,
        };
      }

      return previous;
    },
    {},
  );

  return sql;
});
