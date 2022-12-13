import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { cap } from '../../cap';
import { getShortHostName } from '../../getShortHostName';
import { stdout } from '../../shell';

type ExtractVariableKeyFunction = (parts: string[]) => string;

const MAP_TO_EXTRACTOR: { [prefix: string]: ExtractVariableKeyFunction } = {
  form: ([, part2]) => {
    const [head, ...rest] = part2.split('_');

    return rest.reduce<string>(
      (previous, part) => `${previous}${cap(part)}`,
      head,
    );
  },
  'install-target': () => 'installTarget',
};

export const buildQueryHostDetail: BuildQueryDetailFunction = ({
  keys: hostUUIDs = '*',
} = {}) => {
  const condHostUUIDs = buildKnownIDCondition(hostUUIDs, 'AND hos.host_uuid');

  stdout(`condHostUUIDs=[${condHostUUIDs}]`);

  const query = `
    SELECT
      hos.host_name,
      hos.host_uuid,
      var.variable_name,
      var.variable_value
    FROM variables AS var
    JOIN hosts AS hos
      ON var.variable_source_uuid = hos.host_uuid
    WHERE (
        variable_name LIKE 'form::config_%'
        OR variable_name = 'install-target::enabled'
      )
      ${condHostUUIDs};`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      const [hostName, hostUUID] = output[0];
      const shortHostName = getShortHostName(hostName);

      return output.reduce<
        { hostName: string; hostUUID: string; shortHostName: string } & Record<
          string,
          string
        >
      >(
        (previous, [, , variableName, variableValue]) => {
          const [variablePrefix, ...restVariableParts] =
            variableName.split('::');
          const key = MAP_TO_EXTRACTOR[variablePrefix](restVariableParts);

          previous[key] = variableValue;

          return previous;
        },
        { hostName, hostUUID, shortHostName },
      );
    });

  return { query, afterQueryReturn };
};
