import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { camel } from '../../camel';
import { getShortHostName } from '../../disassembleHostName';
import { stdout } from '../../shell';

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
        a.variable_name, '^${CVAR_PREFIX}\\d+::([^:]+)'
      ) as cvar_name
    FROM variables AS a
    JOIN hosts AS b
      ON a.variable_source_uuid = b.host_uuid
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
        (previous, [, , , variableName, variableValue]) => {
          const [variablePrefix, ...restVariableParts] =
            variableName.split('::');
          const keychain = MAP_TO_EXTRACTOR[variablePrefix](restVariableParts);

          setCvar(keychain, variableValue, previous);

          return previous;
        },
        { hostName, hostType, hostUUID, shortHostName },
      );
    });

  return { query, afterQueryReturn };
};
