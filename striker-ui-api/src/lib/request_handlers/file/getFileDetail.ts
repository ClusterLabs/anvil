import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFileDetail from './buildQueryFileDetail';

const getFileDetail = buildGetRequestHandler((request) =>
  buildQueryFileDetail({ filesUUID: [request.params.fileUUID] }),
);

export default getFileDetail;
