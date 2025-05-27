import { DELETED } from '../consts';

export const sqlServers = () => {
  const sql = `
    SELECT *
    FROM servers
    WHERE server_state != '${DELETED}'`;

  return sql;
};

export const sqlServersWithJobHost = () => {
  const sql = `
    SELECT
      *,
      COALESCE(
        i.server_host_uuid,
        ii.anvil_node1_host_uuid
      ) AS server_job_host_uuid
    FROM (${sqlServers()}) AS i
    JOIN anvils AS ii
      ON i.server_anvil_uuid = ii.anvil_uuid`;

  return sql;
};
