import { getDatabaseConfigData, getLocalHostUUID } from '../../accessModule';
import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { toLocal } from '../../convertHostUUID';
import { match } from '../../match';
import { pout } from '../../shell';

const buildHostConnections = (
  fromHostUUID: string,
  databaseHash: AnvilDataDatabaseHash,
  {
    defaultPort = 5432,
    defaultUser = 'admin',
  }: { defaultPort?: number; defaultUser?: string } = {},
) =>
  Object.entries(databaseHash).reduce<HostConnectionOverview>(
    (
      previous,
      [
        hostUUID,
        {
          host: ipAddress,
          ping,
          port: rPort = defaultPort,
          user = defaultUser,
        },
      ],
    ) => {
      const port = Number(rPort);

      if (hostUUID === fromHostUUID) {
        previous.inbound.port = port;
        previous.inbound.user = user;
      } else {
        previous.peer[ipAddress] = {
          hostUUID,
          ipAddress,
          isPing: ping === '1',
          port,
          user,
        };
      }

      return previous;
    },
    {
      inbound: { ipAddress: {}, port: defaultPort, user: defaultUser },
      peer: {},
    },
  );

export const getHostConnection = buildGetRequestHandler(
  async (request, buildQueryOptions) => {
    const { hostUUIDs: rawHostUUIDs } = request.query;

    let rawDatabaseData: AnvilDataDatabaseHash;

    const hostUUIDField = 'ip_add.ip_address_host_uuid';
    const localHostUUID: string = getLocalHostUUID();
    const { after: condHostUUIDs, before: beforeBuildIDCond } =
      buildUnknownIDCondition(rawHostUUIDs, hostUUIDField, {
        onFallback: () => `${hostUUIDField} = '${localHostUUID}'`,
      });
    const hostUUIDs =
      beforeBuildIDCond.length > 0 ? beforeBuildIDCond : [localHostUUID];

    const getConnectionKey = (hostUUID: string) =>
      toLocal(hostUUID, localHostUUID);

    pout(`condHostUUIDs=[${condHostUUIDs}]`);

    try {
      rawDatabaseData = await getDatabaseConfigData();
    } catch (subError) {
      throw new Error(`Failed to get anvil data; CAUSE: ${subError}`);
    }

    const connections = hostUUIDs.reduce<{
      [hostUUID: string]: HostConnectionOverview;
    }>((previous, hostUUID) => {
      const connectionKey = getConnectionKey(hostUUID);

      previous[connectionKey] = buildHostConnections(hostUUID, rawDatabaseData);

      return previous;
    }, {});

    pout(`connections=[${JSON.stringify(connections, null, 2)}]`);

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = (queryStdout) => {
        let result = queryStdout;

        if (queryStdout instanceof Array) {
          queryStdout.forEach(
            ([ipAddressUUID, hostUUID, ipAddress, network]) => {
              const [, networkType, rawNetworkNumber, rawNetworkLinkNumber] =
                match(network, /^([^\s]+)(\d+)_[^\s]+(\d+)$/);
              const connectionKey = getConnectionKey(hostUUID);

              connections[connectionKey].inbound.ipAddress[ipAddress] = {
                hostUUID,
                ipAddress,
                ipAddressUUID,
                networkLinkNumber: Number(rawNetworkLinkNumber),
                networkNumber: Number(rawNetworkNumber),
                networkType,
              };
            },
          );

          result = connections;
        }

        return result;
      };
    }

    return `SELECT
              ip_add.ip_address_uuid,
              ip_add.ip_address_host_uuid,
              ip_add.ip_address_address,
              CASE
                WHEN ip_add.ip_address_on_type = 'interface'
                  THEN net_int.network_interface_name
                ELSE bon.bond_active_interface
              END AS network_name
            FROM ip_addresses AS ip_add
            LEFT JOIN network_interfaces AS net_int
              ON ip_add.ip_address_on_uuid = net_int.network_interface_uuid
            LEFT JOIN bridges AS bri
              ON ip_add.ip_address_on_uuid = bri.bridge_uuid
            LEFT JOIN bonds AS bon
              ON bri.bridge_uuid = bon.bond_bridge_uuid
                OR ip_add.ip_address_on_uuid = bon.bond_uuid
            WHERE ${condHostUUIDs}
              AND ip_add.ip_address_note != 'DELETED';`;
  },
);
