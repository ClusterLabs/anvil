import { DELETED } from '../consts';

export const sqlNetworkInterfaces = () => {
  const sql = `
    SELECT *
    FROM network_interfaces
    WHERE
        network_interface_operational != '${DELETED}'
      AND
        network_interface_name NOT SIMILAR TO '(vnet\\d+|virbr\\d+-nic)%'`;

  return sql;
};
