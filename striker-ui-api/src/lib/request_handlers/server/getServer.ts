import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { sanitize } from '../../sanitize';
import { poutvar } from '../../shell';

export const getServer = buildGetRequestHandler((request, hooks) => {
  const { anvilUUIDs } = request.query;

  const condAnvilUUIDs = join(sanitize(anvilUUIDs, 'string[]'), {
    beforeReturn: (toReturn) =>
      toReturn ? `AND a.server_anvil_uuid IN (${toReturn})` : '',
    elementWrapper: "'",
    separator: ', ',
  });

  poutvar({ condAnvilUUIDs });

  hooks.afterQueryReturn = buildQueryResultReducer<ServerOverviewList>(
    (previous, row) => {
      const [
        serverUuid,
        serverName,
        serverState,
        anUuid,
        anName,
        anDescription,
        hostUuid,
        hostName,
        hostType,
      ] = row;

      previous[serverUuid] = {
        anvil: {
          description: anDescription,
          name: anName,
          uuid: anUuid,
        },
        host: {
          name: hostName,
          short: getShortHostName(hostName),
          type: hostType,
          uuid: hostUuid,
        },
        name: serverName,
        state: serverState,
        uuid: serverUuid,
      };

      return previous;
    },
    {},
  );

  return `
      SELECT
        a.server_uuid,
        a.server_name,
        a.server_state,
        b.anvil_uuid,
        b.anvil_name,
        b.anvil_description,
        c.host_uuid,
        c.host_name,
        c.host_type
      FROM servers AS a
      JOIN anvils AS b
        ON a.server_anvil_uuid = b.anvil_uuid
      JOIN hosts AS c
        ON a.server_host_uuid = c.host_uuid
      WHERE a.server_state != '${DELETED}'
        ${condAnvilUUIDs}
      ORDER BY a.server_name;`;
});
