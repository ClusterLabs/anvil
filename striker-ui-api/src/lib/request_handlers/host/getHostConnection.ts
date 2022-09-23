import { getAnvilData, getLocalHostUUID } from '../../accessModule';
import { buildIDCondition } from '../../buildIDCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';

export const getHostConnection = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { hostUUIDs } = request.query;

    let localHostUUID: string;
    let rawDatabases: {
      [hostUUID: string]: {
        host: string;
        name: string;
        password: string;
        ping: string;
        port: string;
        user: string;
      };
    };

    try {
      localHostUUID = getLocalHostUUID();
    } catch (subError) {
      throw new Error(`Failed to get local host UUID; CAUSE: ${subError}`);
    }

    const hostUUIDField = 'ip_add.ip_address_host_uuid';
    const condHostUUIDs = buildIDCondition(hostUUIDs, hostUUIDField, {
      onFallback: () => `${hostUUIDField} = '${localHostUUID}'`,
    });

    process.stdout.write(`condHostUUIDs=[${condHostUUIDs}]\n`);

    try {
      ({ database: rawDatabases } = getAnvilData({ database: true }));
    } catch (subError) {
      throw new Error(`Failed to get anvil data; CAUSE: ${subError}`);
    }

    const connections = Object.entries(rawDatabases).reduce<{
      inbound: {
        ipAddresses: {
          [ipAddress: string]: {
            hostUUID: string;
            ipAddress: string;
            ipAddressUUID: string;
            networkLinkNumber: number;
            networkNumber: number;
            networkType: string;
          };
        };
        port: number;
        user: string;
      };
      peer: {
        [ipAddress: string]: {
          hostUUID: string;
          ipAddress: string;
          isPing: boolean;
          port: number;
          user: string;
        };
      };
    }>(
      (
        previous,
        [hostUUID, { host: ipAddress, ping, port: rawPort, user }],
      ) => {
        const port = parseInt(rawPort);

        if (hostUUID === localHostUUID) {
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
      { inbound: { ipAddresses: {}, port: 5432, user: 'admin' }, peer: {} },
    );

    process.stdout.write(`Connections=[\n${JSON.stringify(connections)}\n]\n`);

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = (queryStdout) => {
        let result = queryStdout;

        if (queryStdout instanceof Array) {
          queryStdout.forEach(([ipAddressUUID, ipAddress, network]) => {
            const [, networkType, networkNumber, networkLinkNumber] =
              network.match(/^([^\s]+)(\d+)_[^\s]+(\d+)$/);

            connections.inbound.ipAddresses[ipAddress] = {
              hostUUID: localHostUUID,
              ipAddress,
              ipAddressUUID,
              networkLinkNumber,
              networkNumber,
              networkType,
            };
          });

          result = connections;
        }

        return result;
      };
    }

    return `SELECT
              ip_add.ip_address_uuid,
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
            WHERE ${condHostUUIDs};`;
  },
);
