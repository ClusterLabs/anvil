import { DELETED } from '../consts';

export const sqlScanDrbdVolumes = () => {
  const sql = `
    SELECT *
    FROM scan_drbd_volumes
    WHERE scan_drbd_volume_device_path != '${DELETED}'`;

  return sql;
};
