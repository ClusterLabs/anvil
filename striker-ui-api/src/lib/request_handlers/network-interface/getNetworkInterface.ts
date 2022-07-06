import { sub } from '../../accessModule';

import buildGetRequestHandler from '../buildGetRequestHandler';

export const getNetworkInterface = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    let localHostUUID: string;

    try {
      localHostUUID = sub('host_uuid', {
        subModuleName: 'Get',
      }).stdout;
    } catch (subError) {
      console.log(`Failed to get local host UUID; CAUSE: ${subError}`);

      throw subError;
    }

    console.log(`localHostUUID=[${localHostUUID}]`);

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

    return `
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
      WHERE network_interface_operational != 'DELETE'
        AND network_interface_host_uuid = '${localHostUUID}';`;
  },
);
