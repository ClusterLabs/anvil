import { P_IF } from '../consts';

export const sqlIfaceAlias = () => {
  const sql = `
    SELECT
      network_interface_uuid,
      CASE
        WHEN network_interface_name ~* '${P_IF.full}'
          THEN network_interface_name
        ELSE network_interface_device
      END AS network_interface_alias
    FROM network_interfaces`;

  return sql;
};
