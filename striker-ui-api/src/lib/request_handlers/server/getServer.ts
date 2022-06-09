import buildGetRequestHandler from '../buildGetRequestHandler';
import join from '../../join';
import { sanitizeQS } from '../../sanitizeQS';

export const getServer = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilUUIDs } = request.query;

    const condAnvilUUIDs = join(
      sanitizeQS(anvilUUIDs, { returnType: 'string[]' }),
      {
        beforeReturn: (toReturn) =>
          toReturn ? `AND server_anvil_uuid IN (${toReturn})` : '',
        elementWrapper: "'",
        separator: ', ',
      },
    );

    console.log(`condAnvilsUUID=[${condAnvilUUIDs}]`);

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = (queryStdout) => {
        let result = queryStdout;

        if (queryStdout instanceof Array) {
          result = queryStdout.map<ServerOverview>(
            ([serverUUID, serverName, serverState, serverHostUUID]) => ({
              serverHostUUID,
              serverName,
              serverState,
              serverUUID,
            }),
          );
        }

        return result;
      };
    }

    return `
      SELECT
        server_uuid,
        server_name,
        server_state,
        server_host_uuid
      FROM servers
      WHERE server_state != 'DELETED'
        ${condAnvilUUIDs};`;
  },
);
