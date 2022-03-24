import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFilesDetail from './buildQueryFilesDetail';

const getFiles = buildGetRequestHandler((request) => {
  const { filesUUID } = request.body;

  let query = `
    SELECT
      file_uuid,
      file_name,
      file_size,
      file_type,
      file_md5sum
    FROM files
    WHERE file_type != 'DELETED';`;

  if (filesUUID) {
    query = buildQueryFilesDetail({ filesUUID });
  }

  return query;
});

export default getFiles;
