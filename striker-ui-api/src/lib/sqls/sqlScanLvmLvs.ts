import { DELETED } from '../consts';

export const sqlScanLvmLvs = () => {
  const sql = `
    SELECT *
    FROM scan_lvm_lvs
    WHERE scan_lvm_lv_name != '${DELETED}'`;

  return sql;
};
