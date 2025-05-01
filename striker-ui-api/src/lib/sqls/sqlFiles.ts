import { DELETED } from '../consts';

export const sqlFiles = () => {
  const sql = `
    SELECT *
    FROM files
    WHERE file_type != '${DELETED}'`;

  return sql;
};
