import { DELETED } from '../consts';

export const sqlIpAddresses = () => {
  const sql = `
    SELECT *
    FROM ip_addresses
    WHERE ip_address_note != '${DELETED}'`;

  return sql;
};
