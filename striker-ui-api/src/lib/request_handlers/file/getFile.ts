import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { sanitize } from '../../sanitize';

export const getFile: RequestHandler<
  unknown,
  FileOverviewList,
  unknown,
  FileOverviewListReqQuery
> = buildGetRequestHandler((request, hooks) => {
  const {
    query: { anvilUuid: rAnvilUuid },
  } = request;

  const anvilUuid = sanitize(rAnvilUuid, 'string', {
    modifierType: 'sql',
  });

  let conditions = `a.file_type != '${DELETED}'`;

  if (anvilUuid) {
    conditions += ` AND c.anvil_uuid = '${anvilUuid}'`;
  }

  const query = `
      SELECT
        a.file_uuid,
        a.file_name,
        a.file_size,
        a.file_type,
        a.file_md5sum,
        BOOL_AND(b.file_location_active) AS file_active,
        BOOL_AND(b.file_location_ready) AS file_ready,
        c.anvil_uuid
      FROM files AS a
      JOIN file_locations AS b
        ON b.file_location_file_uuid = a.file_uuid
      JOIN anvils AS c
        ON b.file_location_host_uuid IN (
          c.anvil_node1_host_uuid,
          c.anvil_node2_host_uuid
        )
      WHERE ${conditions}
      GROUP BY a.file_uuid, anvil_uuid
      ORDER BY a.file_name ASC;`;

  const afterQueryReturn = buildQueryResultReducer<FileOverviewList>(
    (previous, row) => {
      const [uuid, name, size, type, checksum, active, ready, anvilUuid] = row;

      if (!(uuid in previous)) {
        previous[uuid] = {
          anvils: {},
          checksum,
          name,
          size,
          type,
          uuid,
        };
      }

      previous[uuid].anvils[anvilUuid] = {
        active: Boolean(active),
        ready: Boolean(ready),
      };

      return previous;
    },
    {},
  );

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
