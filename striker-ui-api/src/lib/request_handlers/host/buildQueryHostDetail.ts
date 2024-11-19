import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { camel } from '../../camel';
import { getShortHostName } from '../../disassembleHostName';
import { selectIfaceAlias } from '../network-interface';
import { pout } from '../../shell';

const CVAR_PREFIX = 'form::config_step';

const MAP_TO_EXTRACTOR: Record<string, (parts: string[]) => string[]> = {
  form: ([, part2]) => {
    const [rHead, ...rest] = part2.split('_');
    const head = rHead.toLowerCase();

    return /^[a-z]+n[0-9]+/.test(head)
      ? ['networks', head, camel(...rest)]
      : [camel(head, ...rest)];
  },
  'install-target': () => ['installTarget'],
  system: ([part1]) => {
    if (part1 === 'configured') {
      return ['hostConfigured'];
    }

    return [];
  },
};

const setCvar = (
  keychain: string[],
  value: string | Tree,
  parent: Tree = {},
): Tree | string => {
  const { 0: key, length } = keychain;

  if (!key) return value;

  const next = 1;
  const { [key]: xv } = parent;

  parent[key] =
    next < length && typeof xv !== 'string'
      ? setCvar(keychain.slice(next), value, xv)
      : value;

  return parent;
};

export const buildQueryHostDetail: BuildQueryDetailFunction = ({
  keys: hostUUIDs = '*',
} = {}) => {
  const condHostUUIDs = buildKnownIDCondition(hostUUIDs, 'WHERE a.host_uuid');

  pout(`condHostUUIDs=[${condHostUUIDs}]`);

  const query = `
    SELECT
      a.host_ipmi,
      a.host_name,
      a.host_status,
      a.host_type,
      a.host_uuid,
      b.anvil_uuid,
      b.anvil_name,
      c.network_interface_uuid,
      SUBSTRING(
        d.network_interface_alias, '([a-z]+n)'
      ) AS network_type,
      SUBSTRING(
        d.network_interface_alias, '[a-z]+n(\\d+)'
      ) AS network_number,
      SUBSTRING(
        d.network_interface_alias, '_(link\\d+)'
      ) AS network_link,
      c.network_interface_mac_address,
      e.ip_address_address,
      e.ip_address_subnet_mask,
      e.ip_address_gateway,
      e.ip_address_default_gateway,
      e.ip_address_dns,
      f.variable_name,
      f.variable_value
    FROM hosts AS a
    LEFT JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid,
        b.anvil_dr1_host_uuid
      )
    LEFT JOIN network_interfaces AS c
      ON c.network_interface_host_uuid = a.host_uuid
    LEFT JOIN (${selectIfaceAlias()}) AS d
      ON d.network_interface_uuid = c.network_interface_uuid
    LEFT JOIN ip_addresses as e
      ON e.ip_address_on_uuid
        IN (
          c.network_interface_uuid,
          c.network_interface_bond_uuid,
          c.network_interface_bridge_uuid
        )
    LEFT JOIN variables AS f
      ON f.variable_source_uuid = a.host_uuid
        AND (
          f.variable_name LIKE ANY (
            ARRAY[
              '${CVAR_PREFIX}%',
              'install-target::enabled',
              'system::configured'
            ]
          )
        )
    ${condHostUUIDs}
    ORDER BY
      a.host_name ASC,
      d.network_interface_alias ASC,
      f.variable_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      if (output.length === 0) return {};

      const {
        0: [
          hostIpmi,
          hostName,
          hostStatus,
          hostType,
          hostUUID,
          anvilUuid,
          anvilName,
        ],
      } = output;

      const shortHostName = getShortHostName(hostName);

      /**
       * Assumes:
       * - ip is not quoted
       * - password is quoted, and it's the last switch in the string
       * - username has no space, and it's not quoted
       *
       * TODO: replace with a package to handle parsing such command strings
       */
      const ipmi: HostIpmi = {
        command: hostIpmi,
        ip: hostIpmi.replace(/^.*--ip\s+([^\s'"]+).*$/, '$1'),
        password: hostIpmi.replace(/^.*--password\s+"(.*)"$/, '$1'),
        username: hostIpmi.replace(/^.*--username\s+(\w+).*$/, '$1'),
      };

      const counts: Record<string, number> = {};

      const partial = output.reduce<
        Omit<HostDetail, 'anvil' | 'hostConfigured'>
      >(
        (previous, row) => {
          const [
            networkInterfaceUuid,
            networkType,
            networkNumber,
            networkLink,
            mac,
            ip,
            subnetMask,
            gateway,
            defaultGateway,
            dns,
            variableName,
            variableValue,
          ] = row.slice(7);

          if (variableName) {
            const [variablePrefix, ...restVariableParts] =
              variableName.split('::');
            const keychain =
              MAP_TO_EXTRACTOR[variablePrefix](restVariableParts);

            setCvar(keychain, variableValue, previous);
          }

          if (networkType && networkNumber && networkLink) {
            // 1st, set the network's values
            const networkAlias = `${networkType}${networkNumber}`;

            const values = {
              ip,
              [`${networkLink}MacToSet`]: mac,
              [`${networkLink}Uuid`]: networkInterfaceUuid,
              sequence: networkNumber,
              subnetMask,
              type: networkType,
            };

            Object.entries(values).forEach(([key, value]) => {
              if (!value) return;

              setCvar(['networks', networkAlias, key], value, previous);
            });

            // 2nd, accumulate the network count
            const { [networkType]: count = 0 } = counts;

            counts[networkType] = Math.max(count, Number(networkNumber));

            // 3rd, set the host's gateway
            if (defaultGateway === '1') {
              previous.dns = dns;
              previous.gateway = gateway;
              previous.gatewayInterface = networkAlias;
            }
          }

          return previous;
        },
        {
          hostName,
          hostStatus,
          hostType,
          hostUUID,
          ipmi,
          networks: {},
          shortHostName,
        },
      );

      Object.entries(counts).forEach(([key, count]) => {
        partial[`${key}Count`] = String(count);
      });

      let anvil: HostOverview['anvil'];

      if (anvilUuid) {
        anvil = { name: anvilName, uuid: anvilUuid };
      }

      const misfit: Pick<HostDetail, 'anvil' | 'hostConfigured'> = {
        anvil,
        hostConfigured: partial.hostConfigured === '1',
      };

      return { ...partial, ...misfit };
    });

  return { query, afterQueryReturn };
};
