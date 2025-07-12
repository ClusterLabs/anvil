import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { Responder } from '../../Responder';
import { queries } from '../../accessModule';
import join from '../../join';
import { getServerQueryStringSchema, ServerQs } from './schemas';
import { poutvar } from '../../shell';
import { sqlHosts, sqlServers } from '../../sqls';

export const getServer: RequestHandler<
  Express.RhParamsDictionary,
  ServerOverviewList,
  Express.RhReqBody,
  ServerQs
> = async (request, response) => {
  const respond = new Responder(response);

  let qs: ServerQs;

  try {
    qs = await getServerQueryStringSchema.validate(request.query);
  } catch (error) {
    return respond.s500(
      '4f925d6',
      `Invalid request query string(s); CAUSE: ${error}`,
    );
  }

  const { anvilUUIDs: anvilUuids } = qs;

  const conditions = {
    job: 'TRUE',
    server: 'TRUE',
  };

  if (anvilUuids?.length) {
    const condition = join(anvilUuids, {
      beforeReturn: (csv) => csv && `anvil_uuid IN (${csv})`,
      elementWrapper: "'",
      separator: ', ',
    });

    conditions.job += ` AND d3.${condition}`;

    conditions.server += ` AND a1.server_${condition}`;
  }

  const sqlGetServers = `
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
    WHERE ${conditions.server}
    ORDER BY a1.server_name;`;

  const sqlScopeJobs = `
    SELECT
      *,
      CASE
        WHEN job_data LIKE '%peer_mode=true%'
          THEN 1
        ELSE 0
      END AS job_on_peer,
      SUBSTRING(
        job_data,
        'server[-_](?:name|uuid)=([^\\n]*)'
      ) AS server_uuid_or_name,
      CASE
        WHEN job_progress < 100
          THEN (
            CASE
              WHEN job_command LIKE '%delete-server%'
                THEN 'deleting'
              WHEN job_command LIKE '%provision-server%'
                THEN 'provisioning'
              WHEN job_command LIKE '%rename-server%'
                THEN 'renaming'
              ELSE NULL
            END
          )
        ELSE NULL
      END as server_state_from_job
    FROM jobs
    WHERE
        job_command LIKE ANY (
          ARRAY[
            '%delete-server%',
            '%provision-server%',
            '%rename-server%'
          ]
        )
      AND
        modified_date > current_timestamp - interval '5 minutes'`;

  const sqlCastServers = `
    SELECT
      *,
      CAST(server_uuid AS text) AS server_text_uuid
    FROM servers`;

  // Check for deleted servers in root query to not only exclude the deleted
  // servers, but also exclude their jobs; jobs for deleted servers will remain
  // if the condition is applied at the join due to "left join"
  const sqlGetJobs = `
    SELECT
      d1.job_uuid,
      d1.job_progress,
      d1.job_on_peer,
      d1.server_uuid_or_name,
      d1.server_state_from_job,
      d2.host_uuid,
      d2.host_name,
      d2.host_short_name,
      d2.host_type,
      d3.anvil_uuid,
      d3.anvil_name,
      d3.anvil_description,
      COALESCE(d4.server_text_uuid, ''),
      COALESCE(d4.server_name, '')
    FROM (${sqlScopeJobs}) AS d1
    JOIN (${sqlHosts()}) AS d2
      ON d2.host_uuid = d1.job_host_uuid
    JOIN anvils AS d3
      ON d2.host_uuid IN (
        d3.anvil_node1_host_uuid,
        d3.anvil_node2_host_uuid
      )
    LEFT JOIN (${sqlCastServers}) AS d4
      ON d1.server_uuid_or_name IN (
        d4.server_text_uuid,
        d4.server_name
      )
    WHERE
        ${conditions.job}
      AND
        d4.server_state != '${DELETED}'
    ORDER BY
      d4.server_name,
      d1.server_uuid_or_name,
      d1.job_on_peer,
      d1.modified_date DESC;`;

  let results: QueryResult[];

  try {
    results = await queries(sqlGetServers, sqlGetJobs);
  } catch (error) {
    return respond.s500('c4bfdf0', `Failed to get servers; CAUSE: ${error}`);
  }

  const servers: ServerOverviewList = {};

  const [serverRows, jobRows] = results;

  serverRows.forEach((row) => {
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
    ] = row as string[];

    let host: ServerOverviewHost | undefined;

    if (hostUuid) {
      host = {
        name: hostName,
        short: hostShortName,
        type: hostType,
        uuid: hostUuid,
      };
    }

    servers[serverUuid] = {
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
  });

  jobRows.forEach((row) => {
    const [
      jobUuid,
      jobProgress,
      jobOnPeer,
      jobServerUuidOrName,
      jobServerState,
      jobHostUuid,
      jobHostName,
      jobHostShortName,
      jobHostType,
      jobAnvilUuid,
      jobAnvilName,
      jobAnvilDescription,
      jobServerUuid,
      jobServerName,
    ] = row as string[];

    const host: ServerOverviewHost = {
      name: jobHostName,
      short: jobHostShortName,
      type: jobHostType,
      uuid: jobHostUuid,
    };

    // Only use name when UUID isn't available, i.e. when server is
    // provisioning (not recorded as a "servers" record yet).
    const id = jobServerUuid || jobServerName || jobServerUuidOrName;

    servers[id] = servers[id] ?? {
      anvil: {
        description: jobAnvilDescription,
        name: jobAnvilName,
        uuid: jobAnvilUuid,
      },
      host,
      name: jobServerName,
      state: '',
      uuid: jobServerUuid,
    };

    const { [id]: server } = servers;

    poutvar({
      jobOnPeer: {
        type: typeof jobOnPeer,
        value: jobOnPeer,
      },
      jobProgress: {
        type: typeof jobProgress,
        value: jobProgress,
      },
    });

    // Only applicable to provisioning jobs
    const peer = Number(jobOnPeer) === 1;

    const progress = Number(jobProgress);

    // Only check state on the main job when there are multiple across
    // different hosts
    if (!peer && jobServerState) {
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
  });

  return respond.s200(servers);
};
