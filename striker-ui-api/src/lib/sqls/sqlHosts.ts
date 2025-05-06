import { DELETED } from '../consts';

export const sqlHosts = () => {
  const sql = `
    SELECT
      *,
      SUBSTRING(host_name, '^([^.]+)') AS host_short_name
    FROM hosts
    WHERE host_key != '${DELETED}'`;

  return sql;
};
