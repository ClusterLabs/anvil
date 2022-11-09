import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { toLocal } from '../../convertHostUUID';
import { sanitizeQS } from '../../sanitizeQS';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
  const { hostUUIDs } = request.query;

  const localHostUUID: string = getLocalHostUUID();

  let query = `
    SELECT
      hos.host_name,
      hos.host_uuid
    FROM hosts AS hos;`;
  let afterQueryReturn: QueryResultModifierFunction | undefined = (
    output: unknown,
  ) => {
    let result = output;

    if (output instanceof Array) {
      result = output.reduce<Record<string, HostOverview>>(
        (previous, [hostName, hostUUID]) => {
          const key = toLocal(hostUUID, localHostUUID);

          previous[key] = { hostName, hostUUID };

          return previous;
        },
        {},
      );
    }

    return result;
  };

  if (hostUUIDs) {
    ({ query, afterQueryReturn } = buildQueryHostDetail({
      keys: sanitizeQS(hostUUIDs, {
        modifierType: 'sql',
        returnType: 'string[]',
      }),
    }));
  }

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = afterQueryReturn;
  }

  return query;
});
