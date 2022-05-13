import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFileDetail from './buildQueryFileDetail';
import { sanitizeQS } from '../../sanitizeQS';

const getFile: RequestHandler = buildGetRequestHandler((request) => {
  const { fileUUIDs } = request.query;

  let query = `
    SELECT
      file_uuid,
      file_name,
      file_size,
      file_type,
      file_md5sum
    FROM files
    WHERE file_type != 'DELETED';`;

  if (fileUUIDs) {
    query = buildQueryFileDetail({
      fileUUIDs: sanitizeQS(fileUUIDs, { returnType: 'string[]' }),
    });
  }

  return query;
});

export default getFile;
