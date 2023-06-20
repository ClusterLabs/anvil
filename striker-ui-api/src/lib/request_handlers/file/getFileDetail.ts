import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryFileDetail } from './buildQueryFileDetail';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';

export const getFileDetail: RequestHandler = buildGetRequestHandler(
  ({ params: { fileUUID } }) =>
    buildQueryFileDetail({ fileUUIDs: [sanitizeSQLParam(fileUUID)] }),
);
