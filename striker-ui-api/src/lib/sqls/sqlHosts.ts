import { DELETED } from '../consts';

export const sqlHosts = () => {
  const sql = `
    SELECT *
    FROM hosts
    WHERE host_key != '${DELETED}'`;

  return sql;
};
