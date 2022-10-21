import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildUnknownIDCondition } from '../../buildCondition';

export const getHost = buildGetRequestHandler((request, buildQueryOptions) => {
  const { hostUUIDs } = request.query;

  const hostUUIDField = 'hos.host_uuid';
  const { after: condHostUUIDs } = buildUnknownIDCondition(
    hostUUIDs,
    hostUUIDField,
    {
      onFallback: () => {
        try {
          return `${hostUUIDField} = '${getLocalHostUUID()}'`;
        } catch (subError) {
          throw new Error(`Failed to get local host UUID; CAUSE: ${subError}`);
        }
      },
    },
  );

  process.stdout.write(`condHostUUIDs=[${condHostUUIDs}]`);

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = (queryStdout) => {
      let result = queryStdout;

      if (queryStdout instanceof Array) {
        result = queryStdout.reduce<Record<string, HostOverview>>(
          (previous, [hostName, hostUUID]) => {
            previous[hostUUID] = { hostName, hostUUID };

            return previous;
          },
          {},
        );
      }

      return result;
    };
  }

  return `SELECT
            hos.host_name,
            hos.host_uuid
          FROM hosts AS hos
          WHERE ${condHostUUIDs};`;
});
