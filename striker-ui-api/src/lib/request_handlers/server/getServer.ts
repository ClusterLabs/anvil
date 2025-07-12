import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { sqlHosts, sqlServers } from '../../sqls';

export const getServer = buildGetRequestHandler((request, hooks) => {
  const { anvilUUIDs } = request.query;

  const condAnvil = join(sanitize(anvilUUIDs, 'string[]'), {
    beforeReturn: (toReturn) => (toReturn ? `anvil_uuid IN (${toReturn})` : ''),
    elementWrapper: "'",
    separator: ', ',
  });

  let condServerAnvil = '';
  let condJobAnvil = '';

  if (condAnvil) {
    condServerAnvil = `AND a1.server_${condAnvil}`;
    condJobAnvil = `AND d3.${condAnvil}`;
  }

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
      a.host_short_name,
      a.host_type,
      d.job_uuid,
      d.job_progress,
      d.job_on_peer,
      d.server_name,
      d.server_state_from_job,
      d.host_uuid,
      d.host_name,
      d.host_short_name,
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
          a3.host_short_name,
          a3.host_type
        FROM (${sqlServers()}) AS a1
        JOIN anvils AS a2
          ON a2.anvil_uuid = a1.server_anvil_uuid
        LEFT JOIN (${sqlHosts()}) AS a3
          ON a3.host_uuid = a1.server_host_uuid
        WHERE TRUE
          ${condServerAnvil}
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
          CASE
            WHEN d1.job_command LIKE '%delete-server%'
              THEN 'deleting'
            WHEN d1.job_command LIKE '%provision-server%'
              THEN 'provisioning'
            WHEN d1.job_command LIKE '%rename-server%'
              THEN 'renaming'
            ELSE NULL
          END as server_state_from_job,
          d2.host_uuid,
          d2.host_name,
          d2.host_short_name,
          d2.host_type,
          d3.anvil_uuid,
          d3.anvil_name,
          d3.anvil_description
        FROM jobs AS d1
        JOIN (${sqlHosts()}) AS d2
          ON d2.host_uuid = d1.job_host_uuid
        JOIN anvils AS d3
          ON d2.host_uuid IN (
            d3.anvil_node1_host_uuid,
            d3.anvil_node2_host_uuid
          )
        WHERE
            d1.job_command LIKE ANY (
              ARRAY[
                '%delete-server%',
                '%provision-server%',
                '%rename-server%'
              ]
            )
          AND
            d1.modified_date > current_timestamp - interval '5 minutes'
          ${condJobAnvil}
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
        hostShortName,
        hostType,
        jobUuid,
        jobProgress,
        jobOnPeer,
        jobServerName,
        jobServerState,
        jobHostUuid,
        jobHostName,
        jobHostShortName,
        jobHostType,
        jobAnvilUuid,
        jobAnvilName,
        jobAnvilDescription,
      ] = row;

      let host: ServerOverviewHost | undefined;

      if (hostUuid) {
        host = {
          name: hostName,
          short: hostShortName,
          type: hostType,
          uuid: hostUuid,
        };
      }

      if (serverUuid) {
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
      }

      if (jobUuid) {
        host = {
          name: jobHostName,
          short: jobHostShortName,
          type: jobHostType,
          uuid: jobHostUuid,
        };

        previous[jobServerName] = previous[jobServerName] ?? {
          anvil: {
            description: jobAnvilDescription,
            name: jobAnvilName,
            uuid: jobAnvilUuid,
          },
          host,
          name: jobServerName,
          state: '',
          uuid: jobUuid,
        };

        const { [jobServerName]: server } = previous;

        const peer = Number(jobOnPeer) === 1;

        const progress = Number(jobProgress);

        if (progress < 100 && jobServerState) {
          // Update server state based on the running job
          server.state = jobServerState;
        }

        server.jobs = server.jobs ?? {};

        server.jobs[jobUuid] = {
          host,
          peer,
          progress,
          uuid: jobUuid,
        };
      }

      return previous;
    },
    {},
  );

  return sql;
});
