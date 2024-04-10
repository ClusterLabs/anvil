import { getLocalHostUUID } from '../../accessModule';
import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../disassembleHostName';
import { sanitize } from '../../sanitize';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
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
      a.host_uuid
    FROM hosts AS a
    ${condition}
    ORDER BY a.host_name ASC;`;

  let afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<{ [hostUUID: string]: HostOverview }>(
      (previous, [hostName, hostStatus, hostType, hostUUID]) => {
        const key = toLocal(hostUUID, localHostUUID);

        previous[key] = {
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

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = afterQueryReturn;
  }

  return query;
});
