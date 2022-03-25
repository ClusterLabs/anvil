import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryFileDetail from './buildQueryFileDetail';

const getFile = buildGetRequestHandler((request) => {
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
    query = buildQueryFileDetail({ filesUUID });
  }

  return query;
});

export default getFile;
