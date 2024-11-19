export const selectIfaceAlias = () =>
  `SELECT
      network_interface_uuid,
      CASE
        WHEN network_interface_name ~* '_link'
          THEN network_interface_name
        ELSE network_interface_device
      END AS network_interface_alias
    FROM network_interfaces`;
