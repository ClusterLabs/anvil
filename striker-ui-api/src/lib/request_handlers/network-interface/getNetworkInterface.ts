import { RequestHandler } from 'express';

import { Responder } from '../../Responder';
import { queries } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { getNetworkInterfaceParamsSchema } from './schemas';
import {
  sqlIpAddresses,
  sqlNetworkInterfaces,
  sqlNetworkInterfacesWithAlias,
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
    FROM (${sqlNetworkInterfaces()}) AS a
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

  const sqlGetSavedNics = `
    WITH all_nics_history AS (
      SELECT
        ROW_NUMBER() OVER(
          PARTITION BY a.network_interface_mac_address
          ORDER BY a.modified_date DESC
        ) AS history_sequence,
        a.network_interface_mac_address,
        a.network_interface_alias,
        e.ip_address_address,
        e.ip_address_subnet_mask,
        e.ip_address_gateway,
        e.ip_address_dns,
        a.network_interface_network_type,
        a.network_interface_network_number,
        a.network_interface_network_link
      FROM (${sqlNetworkInterfacesWithAliasBreakdown(
        `(${sqlNetworkInterfacesWithAlias('history.network_interfaces')}) AS i`,
      )}) AS a
      LEFT JOIN history.bonds AS c
        ON c.bond_uuid = a.network_interface_bond_uuid
      LEFT JOIN history.bridges AS d
        ON d.bridge_uuid IN (
          a.network_interface_bridge_uuid,
          c.bond_bridge_uuid
        )
      JOIN history.ip_addresses AS e
        ON e.ip_address_on_uuid IN (
          a.network_interface_uuid,
          c.bond_uuid,
          d.bridge_uuid
        )
      ORDER BY a.modified_date
    )
    SELECT *
    FROM all_nics_history
    WHERE history_sequence = 1;`;

  let results: QueryResult[];

  try {
    results = await queries(sqlGetHostNics, sqlGetSavedNics);
  } catch (error) {
    return respond.s500(
      'bbdcb0f',
      `Failed to get network interfaces on [${hostUuid}]; CAUSE: ${error}`,
    );
  }

  const [nicRows, savedRows] = results;

  const nics: NetworkInterfaceOverviewList = {};

  const macToUuid: Record<string, string> = {};

  nicRows.forEach((row) => {
    const [uuid, mac, name, state, speed, order, ip, subnetMask, gateway, dns] =
      row as string[];

    macToUuid[mac] = uuid;

    const nic: NetworkInterfaceOverview = {
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

    nics[uuid] = nic;
  });

  savedRows.forEach((row) => {
    const [
      mac,
      alias,
      ip,
      subnetMask,
      gateway,
      dns,
      networkType,
      networkNumber,
      networkLink,
    ] = row.slice(1) as string[];

    if (!networkType) {
      return;
    }

    const uuid = macToUuid[mac];

    if (!uuid) {
      return;
    }

    const nic: NetworkInterfaceOverview = nics[uuid];

    if (!nic) {
      return;
    }

    nic.slot = {
      alias,
      dns,
      gateway,
      ip,
      link: Number(networkLink.replace(/^[^\d]+(\d+)$/, '$1')),
      sequence: Number(networkNumber),
      subnetMask,
      type: networkType,
    };
  });

  return respond.s200(nics);
};
