import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getFile: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const query = `
      SELECT
        file_uuid,
        file_name,
        file_size,
        file_type,
        file_md5sum
      FROM files
      WHERE file_type != '${DELETED}'
      ORDER BY file_name ASC;`;

    const afterQueryReturn = buildQueryResultReducer<FileOverviewList>(
      (previous, row) => {
        const [uuid, name, size, type, checksum] = row;

        previous[uuid] = {
          checksum,
          name,
          size,
          type,
          uuid,
        };

        return previous;
      },
      {},
    );

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
