import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { sanitizeQS } from '../../sanitizeQS';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
  const { hostUUIDs } = request.query;

  let localHostUUID: string;

  try {
    localHostUUID = getLocalHostUUID();
  } catch (subError) {
    throw new Error(`Failed to get local host UUID; CAUSE: ${subError}`);
  }

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
          const key = hostUUID === localHostUUID ? 'local' : hostUUID;

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
