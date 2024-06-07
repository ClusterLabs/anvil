import { getDatabaseConfigData, getLocalHostUUID } from '../../accessModule';
import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { match } from '../../match';
import { pout, poutvar } from '../../shell';

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

    const hostUUIDField = 'a.ip_address_host_uuid';
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

    poutvar(connections, 'connections=');

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = buildQueryResultReducer(
        (previous, row) => {
          const [ipUuid, hostUuid, ip, ifaceId] = row;

          const [, networkType, rNetworkNumber, rNetworkLinkNumber] = match(
            ifaceId,
            /^(.*n)(\d+)_link(\d+)$/,
          );
          const connectionKey = getConnectionKey(hostUuid);

          connections[connectionKey].inbound.ipAddress[ip] = {
            hostUUID: hostUuid,
            ifaceId,
            ipAddress: ip,
            ipAddressUUID: ipUuid,
            networkLinkNumber: Number(rNetworkLinkNumber),
            networkNumber: Number(rNetworkNumber),
            networkType,
          };

          return previous;
        },
        connections,
      );
    }

    return `SELECT
              a.ip_address_uuid,
              a.ip_address_host_uuid,
              a.ip_address_address,
              CASE
                WHEN a.ip_address_on_type = 'interface'
                  THEN (
                    CASE
                      WHEN b.network_interface_name ~* '.*n\\d+_link\\d+'
                        THEN b.network_interface_name
                      ELSE b.network_interface_device
                    END
                  )
                ELSE d.bond_active_interface
              END AS network_name
            FROM ip_addresses AS a
            LEFT JOIN network_interfaces AS b
              ON a.ip_address_on_uuid = b.network_interface_uuid
            LEFT JOIN bridges AS c
              ON a.ip_address_on_uuid = c.bridge_uuid
            LEFT JOIN bonds AS d
              ON c.bridge_uuid = d.bond_bridge_uuid
                OR a.ip_address_on_uuid = d.bond_uuid
            WHERE ${condHostUUIDs}
              AND a.ip_address_note != 'DELETED';`;
  },
);
