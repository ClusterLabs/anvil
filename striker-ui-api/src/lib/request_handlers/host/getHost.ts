import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { getShortHostName } from '../../getShortHostName';
import { sanitize } from '../../sanitize';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
  const { hostUUIDs } = request.query;

  const localHostUUID: string = getLocalHostUUID();

  let query = `
    SELECT
      hos.host_name,
      hos.host_uuid
    FROM hosts AS hos;`;
  let afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<{ [hostUUID: string]: HostOverview }>(
      (previous, [hostName, hostUUID]) => {
        const key = toLocal(hostUUID, localHostUUID);

        previous[key] = {
          hostName,
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
