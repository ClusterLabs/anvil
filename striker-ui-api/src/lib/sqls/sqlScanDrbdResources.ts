import { DELETED } from '../consts';

export const sqlScanDrbdResources = () => {
  const sql = `
    SELECT *
    FROM scan_drbd_resources
    WHERE scan_drbd_resource_xml != '${DELETED}'`;

  return sql;
};
