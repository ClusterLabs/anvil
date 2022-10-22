import { buildKnownIDCondition } from '../../buildCondition';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { stdout } from '../../shell';

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
    WHERE variable_name LIKE 'form::config_%'
      ${condHostUUIDs};`;

  const afterQueryReturn: QueryResultModifierFunction =
    buildQueryResultModifier((output) => {
      const [hostName, hostUUID] = output[0];

      return output.reduce<
        { hostName: string; hostUUID: string } & Record<string, string>
      >(
        (previous, [, variableName, variableValue]) => {
          previous[variableName] = variableValue;

          return previous;
        },
        { hostName, hostUUID },
      );
    });

  return { query, afterQueryReturn };
};