import { DELETED } from '../consts';

export const sqlNetworkInterfaces = () => {
  const sql = `
    SELECT *
    FROM network_interfaces
    WHERE network_interface_operational != '${DELETED}'`;

  return sql;
};
