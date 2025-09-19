import { RequestHandler } from 'express';

import { Responder } from '../../Responder';
import { queries } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { getNetworkInterfaceParamsSchema } from './schemas';
import {
  sqlIpAddresses,
  sqlNetworkInterfacesWithAliasBreakdown,
} from '../../sqls';

export const getNetworkInterface: RequestHandler<
  GetNetworkInterfaceParams,
  NetworkInterfaceOverviewList
> = async (request, response) => {
  const respond = new Responder(response);

  let params: GetNetworkInterfaceParams;

  try {
    params = await getNetworkInterfaceParamsSchema.validate(request.params);
  } catch (error) {
    return respond.s400('bc11764', `Invalid query params; CAUSE: ${error}`);
  }

  const hostUuid = toHostUUID(params.host);

  const sqlGetHostNics = `
    SELECT
      a.network_interface_uuid,
      a.network_interface_mac_address,
      a.network_interface_name,
      a.network_interface_device,
      a.network_interface_alias,
      a.network_interface_network_type,
      a.network_interface_network_number,
      a.network_interface_network_link,
      CASE
        WHEN a.network_interface_link_state = '1'
          AND a.network_interface_operational = 'up'
          THEN 'up'
        ELSE 'down'
      END AS iface_state,
      a.network_interface_speed,
      ROW_NUMBER() OVER(ORDER BY a.modified_date DESC) AS iface_order,
      e.ip_address_address,
      e.ip_address_subnet_mask,
      e.ip_address_gateway,
      e.ip_address_dns
    FROM (${sqlNetworkInterfacesWithAliasBreakdown()}) AS a
    LEFT JOIN bonds AS c
      ON c.bond_uuid = a.network_interface_bond_uuid
    LEFT JOIN bridges AS d
      ON d.bridge_uuid IN (
        a.network_interface_bridge_uuid,
        c.bond_bridge_uuid
      )
    LEFT JOIN (${sqlIpAddresses()}) AS e
      ON e.ip_address_on_uuid IN (
        a.network_interface_uuid,
        c.bond_uuid,
        d.bridge_uuid
      )
    WHERE a.network_interface_host_uuid = '${hostUuid}'
    ORDER BY a.network_interface_name;`;

  let results: QueryResult[];

  try {
    results = await queries(sqlGetHostNics);
  } catch (error) {
    return respond.s500(
      'bbdcb0f',
      `Failed to get network interfaces on [${hostUuid}]; CAUSE: ${error}`,
    );
  }

  const [nicRows] = results;

  const nics: NetworkInterfaceOverviewList = {};

  nicRows.forEach((row) => {
    const [
      uuid,
      mac,
      name,
      device,
      alias,
      networkType,
      networkNumber,
      networkLink,
      state,
      speed,
      order,
      ip,
      subnetMask,
      gateway,
      dns,
    ] = row as string[];

    const nic: NetworkInterfaceOverview = {
      alias,
      device,
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

    if (networkType) {
      nic.slot = {
        link: Number(networkLink.replace(/^[^\d]+(\d+)$/, '$1')),
        network: {
          sequence: Number(networkNumber),
          type: networkType,
        },
      };
    }

    nics[uuid] = nic;
  });

  return respond.s200(nics);
};
