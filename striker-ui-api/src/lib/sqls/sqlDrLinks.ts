import { DELETED } from '../consts';

export const sqlDrLinks = () => {
  const sql = `
    SELECT *
    FROM dr_links
    WHERE dr_link_note != '${DELETED}'`;

  return sql;
};
