import buildGetRequestHandler from '../buildGetRequestHandler';
import join from '../../join';
import { sanitize } from '../../sanitize';

export const getServer = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilUUIDs } = request.query;

    const condAnvilUUIDs = join(
      sanitize(anvilUUIDs, { returnType: 'string[]' }),
      {
        beforeReturn: (toReturn) =>
          toReturn ? `AND ser.server_anvil_uuid IN (${toReturn})` : '',
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
            ([
              serverUUID,
              serverName,
              serverState,
              serverHostUUID,
              anvilUUID,
              anvilName,
            ]) => ({
              serverHostUUID,
              serverName,
              serverState,
              serverUUID,
              anvilUUID,
              anvilName,
            }),
          );
        }

        return result;
      };
    }

    return `
      SELECT
        ser.server_uuid,
        ser.server_name,
        ser.server_state,
        ser.server_host_uuid,
        anv.anvil_uuid,
        anv.anvil_name
      FROM servers AS ser
      JOIN anvils AS anv
        ON ser.server_anvil_uuid = anv.anvil_uuid
      WHERE ser.server_state != 'DELETED'
        ${condAnvilUUIDs};`;
  },
);
