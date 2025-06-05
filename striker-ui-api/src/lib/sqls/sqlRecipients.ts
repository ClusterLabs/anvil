import { DELETED } from '../consts';

export const sqlRecipients = () => {
  const sql = `
    SELECT *
    FROM recipients
    WHERE recipient_name != '${DELETED}'`;

  return sql;
};
