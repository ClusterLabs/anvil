import { DELETED, LOCAL } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { toHostUUID } from '../../convertHostUUID';

export const getNetworkInterface = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const {
      params: { hostUUID: rHostUUID = LOCAL },
    } = request;

    const hostUUID = toHostUUID(rHostUUID);

    const query = `
      SELECT
        network_interface_uuid,
        network_interface_mac_address,
        network_interface_name,
        CASE
          WHEN network_interface_link_state = '1'
            AND network_interface_operational = 'up'
            THEN 'up'
          ELSE 'down'
        END AS network_interface_state,
        network_interface_speed,
        ROW_NUMBER() OVER(ORDER BY modified_date ASC) AS network_interface_order
      FROM network_interfaces
      WHERE network_interface_operational != '${DELETED}'
        AND network_interface_name NOT SIMILAR TO '(vnet\\d+|virbr\\d+-nic)%'
        AND network_interface_host_uuid = '${hostUUID}';`;

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = (queryStdout) => {
        let result = queryStdout;

        if (queryStdout instanceof Array) {
          result = queryStdout.map<NetworkInterfaceOverview>(
            ([
              networkInterfaceUUID,
              networkInterfaceMACAddress,
              networkInterfaceName,
              networkInterfaceState,
              networkInterfaceSpeed,
              networkInterfaceOrder,
            ]) => ({
              networkInterfaceUUID,
              networkInterfaceMACAddress,
              networkInterfaceName,
              networkInterfaceState,
              networkInterfaceSpeed,
              networkInterfaceOrder,
            }),
          );
        }

        return result;
      };
    }

    return query;
  },
);
