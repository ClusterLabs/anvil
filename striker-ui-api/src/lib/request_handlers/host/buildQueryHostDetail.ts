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
      b.variable_name,
      b.variable_value,
      SUBSTRING(
        b.variable_name, '${CVAR_PREFIX_PATTERN}([^:]+)'
      ) as cvar_name,
      SUBSTRING(
        b.variable_name, '${CVAR_PREFIX_PATTERN}([a-z]{2,3})\\d+'
      ) AS network_type,
      SUBSTRING(
        b.variable_name, '${CVAR_PREFIX_PATTERN}[a-z]{2,3}\\d+_(link\\d+)'
      ) AS network_link,
      c.network_interface_uuid
    FROM hosts AS a
    LEFT JOIN variables AS b
      ON b.variable_source_uuid = a.host_uuid
        AND (
          b.variable_name LIKE '${CVAR_PREFIX}%'
          OR b.variable_name = 'install-target::enabled'
        )
    LEFT JOIN network_interfaces AS c
      ON b.variable_name LIKE '%link%_mac%'
        AND b.variable_value = c.network_interface_mac_address
        AND a.host_uuid = c.network_interface_host_uuid
    ${condHostUUIDs}
    ORDER BY a.host_name ASC,
      cvar_name ASC,
      b.variable_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      if (output.length === 0) return {};

      const {
        0: [hostIpmi, hostName, hostStatus, hostType, hostUUID],
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

      return output.reduce<HostDetail>(
        (previous, row) => {
          const {
            5: variableName,
            6: variableValue,
            8: networkType,
            9: networkLink,
            10: networkInterfaceUuid,
          } = row;

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
    });

  return { query, afterQueryReturn };
};
