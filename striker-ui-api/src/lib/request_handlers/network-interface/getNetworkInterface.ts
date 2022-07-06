import buildGetRequestHandler from '../buildGetRequestHandler';

export const getNetworkInterface = buildGetRequestHandler(
  (request, buildQueryOptions) => {
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
        network_interface_operational,
        network_interface_speed,
        ROW_NUMBER() OVER(ORDER BY modified_date ASC) AS network_interface_order
      FROM network_interfaces;`;
  },
);
