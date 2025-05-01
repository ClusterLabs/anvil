import { DELETED } from '../../consts';

import { query } from '../../accessModule';
import { camel } from '../../camel';
import { setChain } from '../../chain';
import { getHostIpmi } from '../../disassembleCommand';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { ifaceAliasReps, selectIfaceAlias } from '../network-interface';
import { perr, poutvar } from '../../shell';

const patterns = {
  network: {
    id: new RegExp(`^${ifaceAliasReps.id}`),
  },
};

const setvarParams: Record<
  string,
  (
    parts: string[],
    value: string,
  ) => [string[], value: boolean | number | string]
> = {
  form: (parts, original) => {
    const [, part2 = ''] = parts;

    const part = part2.toLocaleLowerCase();

    const [head = '', ...rest] = part.split('_');

    let chain: string[];

    let value: boolean | string = original;

    if (patterns.network.id.test(head)) {
      chain = ['netconf', 'networks', head, camel(...rest)];

      if (/create_bridge/.test(part2)) {
        value = original === '1';
      }
    } else if (/^dns$|^gateway|count$/.test(part)) {
      chain = ['netconf', camel(head, ...rest)];
    } else {
      chain = [camel(head, ...rest)];
    }

    return [chain, value];
  },
  'install-target': (parts, original) => [
    ['installTarget'],
    original === 'enabled',
  ],
  system: (parts, original) => [['configured'], original === '1'],
};

export const buildHostDetailList = async ({
  uuids = [],
}: {
  uuids?: string[];
} = {}): Promise<HostDetailList> => {
  let conditions = `a.host_key != '${DELETED}'`;

  if (uuids.length) {
    conditions += join(uuids, {
      beforeReturn: (csv) => csv && ` AND a.host_uuid IN (${csv})`,
      elementWrapper: "'",
      separator: ', ',
    });
  }

  let rows: string[][];

  const sqlGetHosts = `
    SELECT
      a.host_uuid,
      a.host_name,
      a.host_type,
      a.host_ipmi,
      a.host_status,
      b.anvil_uuid,
      b.anvil_name,
      b.anvil_description
    FROM hosts AS a
    LEFT JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid
      )
    WHERE ${conditions}
    ORDER BY
      a.host_name;`;

  try {
    rows = await query(sqlGetHosts);
  } catch (error) {
    perr(`Failed to get host(s); CAUSE: ${error}`);

    throw error;
  }

  const hosts: HostDetailList = {};

  rows.forEach((row) => {
    const [
      uuid,
      name,
      type,
      ipmiCommand,
      status,
      anvilUuid,
      anvilName,
      anvilDescription,
    ] = row;

    const ipmi = getHostIpmi(ipmiCommand);
    const short = getShortHostName(name);

    const host: HostDetailAlt = {
      configured: false,
      ipmi,
      name,
      netconf: {
        dns: '',
        gateway: '',
        gatewayInterface: '',
        networks: {},
      },
      short,
      status,
      type,
      uuid,
    };

    if (anvilUuid) {
      host.anvil = {
        description: anvilDescription,
        name: anvilName,
        uuid: anvilUuid,
      };
    }

    hosts[uuid] = host;
  });

  poutvar(hosts, 'hosts=');

  const hostUuidsCsv = join(Object.keys(hosts), {
    elementWrapper: "'",
    separator: ', ',
  });

  const sqlGetIfaces = `
    SELECT
      a.network_interface_uuid,
      a.network_interface_host_uuid,
      a.network_interface_mac_address,
      SUBSTRING(
        b.network_interface_alias, '${ifaceAliasReps.xType}'
      ) AS network_type,
      SUBSTRING(
        b.network_interface_alias, '${ifaceAliasReps.xNum}'
      ) AS network_number,
      SUBSTRING(
        b.network_interface_alias, '${ifaceAliasReps.xLink}'
      ) AS network_link,
      c.ip_address_address,
      c.ip_address_subnet_mask,
      c.ip_address_gateway,
      c.ip_address_default_gateway,
      c.ip_address_dns
    FROM network_interfaces AS a
    JOIN (${selectIfaceAlias()}) AS b
      ON b.network_interface_uuid = a.network_interface_uuid
    LEFT JOIN ip_addresses as c
      ON c.ip_address_on_uuid
        IN (
          a.network_interface_uuid,
          a.network_interface_bond_uuid,
          a.network_interface_bridge_uuid
        )
    WHERE a.network_interface_host_uuid IN (${hostUuidsCsv})
    ORDER BY
      b.network_interface_alias;`;

  try {
    rows = await query(sqlGetIfaces);
  } catch (error) {
    perr(`Failed to get host interface(s); CAUSE: ${error}`);

    throw error;
  }

  const counts: Record<string, number> = {};

  rows.forEach((row) => {
    const [
      uuid,
      hostUuid,
      mac,
      type,
      sequence,
      link,
      ip,
      subnetMask,
      gateway,
      defaultGateway,
      dns,
    ] = row;

    const { [hostUuid]: host } = hosts;

    if ([host, type, sequence, link].some((v) => !v)) {
      return;
    }

    const { netconf } = host;

    const alias = `${type}${sequence}`;

    // 1st, set the network's values
    Object.entries({
      ip,
      [`${link}MacToSet`]: mac,
      [`${link}Uuid`]: uuid,
      sequence: Number(sequence),
      subnetMask,
      type,
    }).forEach((entry) => {
      const [k, v] = entry;

      if (!v) {
        return;
      }

      setChain([alias, k], v, netconf.networks);
    });

    // 2nd, accumulate the network count
    counts[type] = (counts[type] ?? 0) + 1;

    // 3rd, set the host's gateway
    if (defaultGateway === '1') {
      netconf.dns = dns;
      netconf.gateway = gateway;
      netconf.gatewayInterface = alias;
    }
  });

  poutvar(hosts, 'hosts=');

  const sqlGetVariables = `
    SELECT
      a.variable_source_uuid,
      a.variable_name,
      a.variable_value,
      b.network_interface_uuid
    FROM variables AS a
    LEFT JOIN network_interfaces AS b
      ON b.network_interface_mac_address = a.variable_value
    WHERE
        a.variable_source_uuid IN (${hostUuidsCsv})
      AND
        a.variable_name LIKE ANY (
          ARRAY[
            'form::config_step%',
            'install-target::enabled',
            'system::configured'
          ]
        )
    ORDER BY
      a.variable_name;`;

  try {
    rows = await query(sqlGetVariables);
  } catch (error) {
    perr(`Failed to get host variable(s); CAUSE: ${error}`);

    throw error;
  }

  rows.forEach((row) => {
    const [hostUuid = '', name, original, ifaceUuid] = row;

    const { [hostUuid]: host } = hosts;

    if ([host, name].some((v) => !v)) {
      return;
    }

    const [prefix, ...parts] = name.split('::');

    const params = setvarParams[prefix]?.call(null, parts, original);

    if (!params) {
      return;
    }

    const [chain, value] = params;

    setChain(chain, value, host);

    // Set the network interface UUID based on a previously used MAC
    if (!/mac_to_set/.test(name)) {
      return;
    }

    const last = chain.pop();

    if (!last) {
      return;
    }

    const tail = last.replace('MacToSet', 'Uuid');

    chain.push(tail);

    setChain(chain, ifaceUuid, host);

    const matches = name.match(patterns.network.id);

    if (!matches) {
      return;
    }

    const [, type, sequence] = matches;

    const alias = `${type}${sequence}`;

    Object.entries({
      sequence: Number(sequence),
      type,
    }).forEach((entry) => {
      const [k, v] = entry;

      if (!v) {
        return;
      }

      setChain([alias, k], v, host.netconf.networks);
    });
  });

  poutvar(hosts, 'hosts=');

  return hosts;
};
