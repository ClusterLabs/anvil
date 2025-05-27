import { DELETED } from '../consts';

export const sqlScanDrbdPeers = () => {
  const sql = `
    SELECT *
    FROM scan_drbd_peers
    WHERE scan_drbd_peer_connection_state != '${DELETED}'`;

  return sql;
};
