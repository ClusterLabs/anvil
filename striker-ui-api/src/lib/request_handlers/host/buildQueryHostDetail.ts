import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { camel } from '../../camel';
import { getShortHostName } from '../../disassembleHostName';
import { pout } from '../../shell';

const CVAR_PREFIX = 'form::config_step';
const CVAR_PREFIX_PATTERN = `^${CVAR_PREFIX}\\d+::`;

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
  value: string,
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
      c.variable_name,
      c.variable_value,
      SUBSTRING(
        c.variable_name, '${CVAR_PREFIX_PATTERN}([^:]+)'
      ) as cvar_name,
      SUBSTRING(
        c.variable_name, '${CVAR_PREFIX_PATTERN}([a-z]{2,3})\\d+'
      ) AS network_type,
      SUBSTRING(
        c.variable_name, '${CVAR_PREFIX_PATTERN}[a-z]{2,3}\\d+_(link\\d+)'
      ) AS network_link,
      d.network_interface_uuid
    FROM hosts AS a
    LEFT JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid,
        b.anvil_dr1_host_uuid
      )
    LEFT JOIN variables AS c
      ON c.variable_source_uuid = a.host_uuid
        AND (
          c.variable_name LIKE '${CVAR_PREFIX}%'
          OR c.variable_name IN (
            'install-target::enabled',
            'system::configured'
          )
        )
    LEFT JOIN network_interfaces AS d
      ON c.variable_name LIKE '%link%_mac%'
        AND c.variable_value = d.network_interface_mac_address
        AND a.host_uuid = d.network_interface_host_uuid
    ${condHostUUIDs}
    ORDER BY a.host_name ASC,
      cvar_name ASC,
      c.variable_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      if (output.length === 0) return {};

      const {
        0: [hostIpmi, hostName, hostStatus, hostType, hostUUID, anUuid, anName],
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

      const partial = output.reduce<
        Omit<HostDetail, 'anvil' | 'hostConfigured'>
      >(
        (previous, row) => {
          const [
            variableName,
            variableValue,
            networkType,
            networkLink,
            networkInterfaceUuid,
          ] = row.slice(7);

          if (!variableName) return previous;

          const [variablePrefix, ...restVariableParts] =
            variableName.split('::');
          const keychain = MAP_TO_EXTRACTOR[variablePrefix](restVariableParts);

          setCvar(keychain, variableValue, previous);

          if (networkLink) {
            keychain[keychain.length - 1] = `${networkLink}Uuid`;

            setCvar(keychain, networkInterfaceUuid, previous);
          } else if (networkType) {
            keychain[keychain.length - 1] = 'type';

            setCvar(keychain, networkType, previous);
          }

          return previous;
        },
        {
          hostName,
          hostStatus,
          hostType,
          hostUUID,
          ipmi,
          shortHostName,
        },
      );

      let anvil: HostOverview['anvil'];

      if (anUuid) {
        anvil = { name: anName, uuid: anUuid };
      }

      const misfit: Pick<HostDetail, 'anvil' | 'hostConfigured'> = {
        anvil,
        hostConfigured: partial.hostConfigured === '1',
      };

      return { ...partial, ...misfit };
    });

  return { query, afterQueryReturn };
};
