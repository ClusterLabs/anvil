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
        toReturn ? `AND a.server_anvil_uuid IN (${toReturn})` : '',
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
        a.server_uuid,
        a.server_name,
        a.server_state,
        a.server_host_uuid,
        b.anvil_uuid,
        b.anvil_name
      FROM servers AS a
      JOIN anvils AS b
        ON a.server_anvil_uuid = b.anvil_uuid
      WHERE a.server_state != '${DELETED}'
        ${condAnvilUUIDs}
      ORDER BY a.server_name;`;
  },
);
