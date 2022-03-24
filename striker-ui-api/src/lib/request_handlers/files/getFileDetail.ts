import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFilesDetail from './buildQueryFilesDetail';

const getFileDetail = buildGetRequestHandler((request) =>
  buildQueryFilesDetail({ filesUUID: [request.params.fileUUID] }),
);

export default getFileDetail;
