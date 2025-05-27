import { DELETED } from '../consts';

export const sqlScanCluster = () => {
  const sql = `
    SELECT *
    FROM scan_cluster
    WHERE scan_cluster_cib != '${DELETED}'`;

  return sql;
};
