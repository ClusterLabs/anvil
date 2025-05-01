import { LOCAL } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toHostUUID } from '../../convertHostUUID';
import { sqlIpAddresses, sqlNetworkInterfaces } from '../../sqls';

export const getNetworkInterface = buildGetRequestHandler((request, hooks) => {
  const {
    params: { hostUUID: rHostUuid = LOCAL },
  } = request;

  const hostUuid = toHostUUID(rHostUuid);

  const query = `
    SELECT
      a.network_interface_uuid,
      a.network_interface_mac_address,
      a.network_interface_name,
      CASE
        WHEN a.network_interface_link_state = '1'
          AND a.network_interface_operational = 'up'
          THEN 'up'
        ELSE 'down'
      END AS iface_state,
      a.network_interface_speed,
      ROW_NUMBER() OVER(ORDER BY a.modified_date DESC) AS iface_order,
      d.ip_address_address,
      d.ip_address_subnet_mask,
      d.ip_address_gateway,
      d.ip_address_dns
    FROM (${sqlNetworkInterfaces()}) AS a
    LEFT JOIN bonds AS b
      ON b.bond_uuid = a.network_interface_bond_uuid
    LEFT JOIN bridges AS c
      ON c.bridge_uuid IN (
        a.network_interface_bridge_uuid,
        b.bond_bridge_uuid
      )
    LEFT JOIN (${sqlIpAddresses()}) AS d
      ON d.ip_address_on_uuid IN (
        a.network_interface_uuid,
        b.bond_uuid,
        c.bridge_uuid
      )
    WHERE a.network_interface_host_uuid = '${hostUuid}'
    ORDER BY a.network_interface_name;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultReducer<NetworkInterfaceOverviewList>((previous, row) => {
      const [
        uuid,
        mac,
        name,
        state,
        speed,
        order,
        ip,
        subnetMask,
        gateway,
        dns,
      ] = row;

      previous[uuid] = {
        dns,
        gateway,
        ip,
        mac,
        name,
        order: Number(order),
        speed: Number(speed),
        state,
        subnetMask,
        uuid,
      };

      return previous;
    }, {});

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
