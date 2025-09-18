import { RequestHandler } from 'express';

import { Responder } from '../../Responder';
import { queries } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { getNetworkInterfaceParamsSchema } from './schemas';
import { sqlIpAddresses, sqlNetworkInterfaces } from '../../sqls';

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
      state,
      speed,
      order,
      ip,
      subnetMask,
      gateway,
      dns,
    ] = row as string[];

    nics[uuid] = {
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
  });

  return respond.s200(nics);
};
