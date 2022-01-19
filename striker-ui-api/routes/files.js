const express = require('express');

const accessDB = require('../lib/accessDB');
const getFilesOverview = require('../lib/request_handlers/files/getFilesOverview');
const getFileDetail = require('../lib/request_handlers/files/getFileDetail');
const uploadSharedFiles = require('../middlewares/uploadSharedFiles');

const router = express.Router();

router
  .get('/', getFilesOverview)
  .get('/:fileUUID', getFileDetail)
  .post('/', uploadSharedFiles.single('file'), ({ file, body }, response) => {
    console.log('Receiving shared file.');

    if (file) {
      console.log(`file:`);
      console.dir(file);

      console.log('body:');
      console.dir(body);

      response.status(200).send();
    }
  })
  .put('/:fileUUID', (request, response) => {
    console.log('Begin edit single file.');

    const { fileUUID } = request.params;
    const { fileName, fileLocations, fileType } = request.body;

    let query = '';

    if (fileName || fileType) {
      query += `
        UPDATE files
        SET
          ${fileName ? `file_name = '${fileName}',` : ''}
          ${fileType ? `file_type = '${fileType}',` : ''}
          modified_date = '${accessDB.sub('refresh_timestamp').stdout}'
        WHERE
          file_uuid = '${fileUUID}';`;
    }

    if (fileLocations) {
      fileLocations.forEach(({ fileLocationUUID, isFileLocationActive }) => {
        const fileLocationActive = isFileLocationActive ? 1 : 0;

        query += `
          UPDATE file_locations
          SET
            file_location_active = '${fileLocationActive}',
            modified_date = '${accessDB.sub('refresh_timestamp').stdout}'
          WHERE file_location_uuid = '${fileLocationUUID}';`;
      });
    }

    console.log(`Query (type=[${typeof query}]): [${query}]`);

    let queryStdout;

    try {
      ({ stdout: queryStdout } = accessDB.query(query, 'write'));
    } catch (queryError) {
      console.log(`Query error: ${queryError}`);

      response.status(500).send();
    }

    console.log(
      `Query stdout (type=[${typeof queryStdout}]): ${JSON.stringify(
        queryStdout,
        null,
        2,
      )}`,
    );

    response.status(200).send(queryStdout);
  });

module.exports = router;
