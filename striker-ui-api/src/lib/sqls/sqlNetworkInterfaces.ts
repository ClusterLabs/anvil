import { DELETED, P_IF } from '../consts';

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

export const sqlNetworkInterfacesWithAlias = (
  source = `(${sqlNetworkInterfaces()}) AS i`,
) => {
  const sql = `
    SELECT
      *,
      CASE
        WHEN network_interface_device ~* '${P_IF.full}'
          THEN network_interface_device
        ELSE network_interface_name
      END AS network_interface_alias
    FROM ${source}`;

  return sql;
};

export const sqlNetworkInterfacesWithAliasBreakdown = (
  source = `(${sqlNetworkInterfacesWithAlias()}) AS i`,
) => {
  const sql = `
    SELECT
      *,
      SUBSTRING(
        network_interface_alias, '${P_IF.xType}'
      ) AS network_interface_network_type,
      SUBSTRING(
        network_interface_alias, '${P_IF.xNum}'
      ) AS network_interface_network_number,
      SUBSTRING(
        network_interface_alias, '${P_IF.xLink}'
      ) AS network_interface_network_link
    FROM ${source}`;

  return sql;
};
