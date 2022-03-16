import buildGetFiles from './buildGetFiles';

const getFilesOverview = buildGetFiles(`
SELECT
  file_uuid,
  file_name,
  file_size,
  file_type,
  file_md5sum
FROM files
WHERE file_type != 'DELETED';`);

export default getFilesOverview;
