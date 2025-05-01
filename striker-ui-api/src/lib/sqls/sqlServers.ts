import { DELETED } from '../consts';

export const sqlServers = () => {
  const sql = `
    SELECT *
    FROM servers
    WHERE server_state != '${DELETED}'`;

  return sql;
};
