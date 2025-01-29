import { getLocalHostUUID } from '../../accessModule';
import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../disassembleHostName';
import { sanitize } from '../../sanitize';

export const getHost = buildGetRequestHandler((request, hooks) => {
  const { hostUUIDs, types: hostTypes } = request.query;

  const localHostUUID: string = getLocalHostUUID();

  const { after: typeCondition } = buildUnknownIDCondition(
    hostTypes,
    'a.host_type',
  );

  let condition = '';

  if (typeCondition.length > 0) {
    condition += `WHERE ${typeCondition}`;
  }

  let query = `
    SELECT
      a.host_name,
      a.host_status,
      a.host_type,
      a.host_uuid,
      b.anvil_uuid,
      b.anvil_name,
      c.variable_value
    FROM hosts AS a
    LEFT JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid
      )
    LEFT JOIN variables AS c
      ON c.variable_name = 'system::configured'
        AND c.variable_source_table = 'hosts'
        AND a.host_uuid = c.variable_source_uuid
    ${condition}
    ORDER BY a.host_name ASC;`;

  let afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<{ [hostUUID: string]: HostOverview }>(
      (previous, row) => {
        const [
          hostName,
          hostStatus,
          hostType,
          hostUUID,
          anUuid,
          anName,
          hostConfigured,
        ] = row;

        const key = toLocal(hostUUID, localHostUUID);

        let anvil: HostOverview['anvil'];

        if (anUuid) {
          anvil = { name: anName, uuid: anUuid };
        }

        previous[key] = {
          anvil,
          hostConfigured: hostConfigured === '1',
          hostName,
          hostStatus,
          hostType,
          hostUUID,
          shortHostName: getShortHostName(hostName),
        };

        return previous;
      },
      {},
    );

  if (hostUUIDs) {
    // TODO: the output of host detail is designed to only contain one
    // host, correct it to support multiple hosts to allow selecting
    // multiple hosts' detail.
    ({ query, afterQueryReturn } = buildQueryHostDetail({
      keys: sanitize(hostUUIDs, 'string[]', {
        modifierType: 'sql',
      }),
    }));
  }

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
