import { sqlScanCluster } from './sqlScanCluster';

export const sqlScanClusterNodes = () => {
  const sql = `
    SELECT i.*
    FROM scan_cluster_nodes AS i
    JOIN (${sqlScanCluster()}) AS ii
      ON ii.scan_cluster_uuid = i.scan_cluster_node_scan_cluster_uuid`;

  return sql;
};
