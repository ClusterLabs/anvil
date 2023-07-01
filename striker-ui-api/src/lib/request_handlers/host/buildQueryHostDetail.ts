import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { camel } from '../../camel';
import { getShortHostName } from '../../disassembleHostName';
import { stdout } from '../../shell';

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
  const condHostUUIDs = buildKnownIDCondition(hostUUIDs, 'AND b.host_uuid');

  stdout(`condHostUUIDs=[${condHostUUIDs}]`);

  const query = `
    SELECT
      b.host_name,
      b.host_type,
      b.host_uuid,
      a.variable_name,
      a.variable_value,
      SUBSTRING(
        a.variable_name, '${CVAR_PREFIX_PATTERN}([^:]+)'
      ) as cvar_name,
      SUBSTRING(
        a.variable_name, '${CVAR_PREFIX_PATTERN}([a-z]{2,3})\\d+'
      ) AS network_type,
      SUBSTRING(
        a.variable_name, '${CVAR_PREFIX_PATTERN}[a-z]{2,3}\\d+_(link\\d+)'
      ) AS network_link,
      c.network_interface_uuid
    FROM variables AS a
    JOIN hosts AS b
      ON a.variable_source_uuid = b.host_uuid
    LEFT JOIN network_interfaces AS c
      ON a.variable_name LIKE '%link%_mac%'
        AND a.variable_value = c.network_interface_mac_address
        AND b.host_uuid = c.network_interface_host_uuid
    WHERE (
        variable_name LIKE '${CVAR_PREFIX}%'
        OR variable_name = 'install-target::enabled'
      )
      ${condHostUUIDs}
    ORDER BY cvar_name ASC,
      a.variable_name ASC;`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      const [hostName, hostType, hostUUID] = output[0];
      const shortHostName = getShortHostName(hostName);

      return output.reduce<
        {
          hostName: string;
          hostType: string;
          hostUUID: string;
          shortHostName: string;
        } & Tree
      >(
        (
          previous,
          [
            ,
            ,
            ,
            variableName,
            variableValue,
            ,
            networkType,
            networkLink,
            networkInterfaceUuid,
          ],
        ) => {
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
        { hostName, hostType, hostUUID, shortHostName },
      );
    });

  return { query, afterQueryReturn };
};
