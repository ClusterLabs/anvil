import buildGetFiles from './buildGetFiles';
import buildQueryFilesDetail from './buildQueryFilesDetail';

const getFileDetail = buildGetFiles((request) =>
  buildQueryFilesDetail({ filesUUID: [request.params.fileUUID] }),
);

export default getFileDetail;
