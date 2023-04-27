import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryFileDetail } from './buildQueryFileDetail';
import { sanitize } from '../../sanitize';

export const getFile: RequestHandler = buildGetRequestHandler((request) => {
  const { fileUUIDs } = request.query;

  let query = `
    SELECT
      file_uuid,
      file_name,
      file_size,
      file_type,
      file_md5sum
    FROM files
    WHERE file_type != '${DELETED}';`;

  if (fileUUIDs) {
    query = buildQueryFileDetail({
      fileUUIDs: sanitize(fileUUIDs, 'string[]', {
        modifierType: 'sql',
      }),
    });
  }

  return query;
});
