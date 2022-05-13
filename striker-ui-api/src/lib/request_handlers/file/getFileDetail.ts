import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFileDetail from './buildQueryFileDetail';

const getFileDetail: RequestHandler = buildGetRequestHandler((request) =>
  buildQueryFileDetail({ fileUUIDs: [request.params.fileUUID] }),
);

export default getFileDetail;
