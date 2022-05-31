import buildGetRequestHandler from '../buildGetRequestHandler';
import join from '../../join';

export const getServer = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilsUUID } = request.body;

    const condAnvilsUUID = join(anvilsUUID, {
      beforeReturn: (toReturn) =>
        toReturn ? `AND server_anvil_uuid IN (${toReturn})` : '',
      elementWrapper: "'",
      separator: ', ',
    });

    console.log(`condAnvilsUUID=[${condAnvilsUUID}]`);

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
      ${condAnvilsUUID};`;
  },
);
