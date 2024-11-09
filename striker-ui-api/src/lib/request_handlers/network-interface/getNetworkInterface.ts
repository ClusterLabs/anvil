import { DELETED, LOCAL } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toHostUUID } from '../../convertHostUUID';

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
        b.ip_address_address,
        b.ip_address_subnet_mask,
        b.ip_address_gateway,
        b.ip_address_dns
      FROM network_interfaces AS a
      LEFT JOIN ip_addresses AS b
        ON b.ip_address_note != '${DELETED}'
          AND b.ip_address_on_uuid = a.network_interface_uuid
      WHERE a.network_interface_operational != '${DELETED}'
        AND a.network_interface_name NOT SIMILAR TO '(vnet\\d+|virbr\\d+-nic)%'
        AND a.network_interface_host_uuid = '${hostUuid}'
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
