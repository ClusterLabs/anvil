import { getLocalHostUUID } from '../../accessModule';
import { buildUnknownIDCondition } from '../../buildCondition';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../getShortHostName';
import { sanitize } from '../../sanitize';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
  const { hostUUIDs, types: hostTypes } = request.query;

  const localHostUUID: string = getLocalHostUUID();

  const { after: typeCondition } = buildUnknownIDCondition(
    hostTypes,
    'hos.host_type',
  );

  let condition = '';

  if (typeCondition.length > 0) {
    condition += `WHERE ${typeCondition}`;
  }

  let query = `
    SELECT
      hos.host_name,
      hos.host_type,
      hos.host_uuid
    FROM hosts AS hos
    ${condition};`;
  let afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<{ [hostUUID: string]: HostOverview }>(
      (previous, [hostName, hostType, hostUUID]) => {
        const key = toLocal(hostUUID, localHostUUID);

        previous[key] = {
          hostName,
          hostType,
          hostUUID,
          shortHostName: getShortHostName(hostName),
        };

        return previous;
      },
      {},
    );

  if (hostUUIDs) {
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
