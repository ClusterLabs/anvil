import { DELETED } from '../consts';

export const sqlScanLvmVgs = () => {
  const sql = `
    SELECT *
    FROM scan_lvm_vgs
    WHERE scan_lvm_vg_name != '${DELETED}'`;

  return sql;
};
