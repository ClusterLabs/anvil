import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { poutvar } from '../../shell';

export const getServer = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const { anvilUUIDs } = request.query;

    const condAnvilUUIDs = join(sanitize(anvilUUIDs, 'string[]'), {
      beforeReturn: (toReturn) =>
        toReturn ? `AND ser.server_anvil_uuid IN (${toReturn})` : '',
      elementWrapper: "'",
      separator: ', ',
    });

    poutvar({ condAnvilUUIDs });

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = buildQueryResultReducer<
        ServerOverview[]
      >(
        (
          previous,
          [
            serverUUID,
            serverName,
            serverState,
            serverHostUUID,
            anvilUUID,
            anvilName,
          ],
        ) => {
          previous.push({
            anvilName,
            anvilUUID,
            serverHostUUID,
            serverName,
            serverState,
            serverUUID,
          });

          return previous;
        },
        [],
      );
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
      WHERE ser.server_state != '${DELETED}'
        ${condAnvilUUIDs};`;
  },
);
