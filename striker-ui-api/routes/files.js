const express = require('express');

const {
  dbJobAnvilSyncShared,
  dbQuery,
  dbSubRefreshTimestamp,
} = require('../lib/accessDB');
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
    const anvilSyncSharedFunctions = [];

    let query = '';

    if (fileName) {
      const [[oldFileName]] = dbQuery(
        `SELECT file_name FROM files WHERE file_uuid = '${fileUUID}';`,
      ).stdout;
      console.log(`oldFileName=[${oldFileName}],newFileName=[${fileName}]`);

      if (fileName !== oldFileName) {
        query += `
        UPDATE files
        SET
          file_name = '${fileName}',
          modified_date = '${dbSubRefreshTimestamp()}'
        WHERE file_uuid = '${fileUUID}';`;

        anvilSyncSharedFunctions.push(() =>
          dbJobAnvilSyncShared(
            'rename',
            `file_uuid=${fileUUID}\nold_name=${oldFileName}\nnew_name=${fileName}`,
            '0138',
            '0139',
          ),
        );
      }
    }

    if (fileType) {
      query += `
        UPDATE files
        SET
          file_type = '${fileType}',
          modified_date = '${dbSubRefreshTimestamp()}'
        WHERE file_uuid = '${fileUUID}';`;

      anvilSyncSharedFunctions.push(() =>
        dbJobAnvilSyncShared(
          'check_mode',
          `file_uuid=${fileUUID}`,
          '0143',
          '0144',
        ),
      );
    }

    if (fileLocations) {
      fileLocations.forEach(({ fileLocationUUID, isFileLocationActive }) => {
        let fileLocationActive = 0;
        let jobName = 'purge';
        let jobTitle = '0136';
        let jobDescription = '0137';

        if (isFileLocationActive) {
          fileLocationActive = 1;
          jobName = 'pull_file';
          jobTitle = '0132';
          jobDescription = '0133';
        }

        query += `
          UPDATE file_locations
          SET
            file_location_active = '${fileLocationActive}',
            modified_date = '${dbSubRefreshTimestamp()}'
          WHERE file_location_uuid = '${fileLocationUUID}';`;

        const targetHosts = dbQuery(
          `SELECT
              anv.anvil_node1_host_uuid,
              anv.anvil_node2_host_uuid,
              anv.anvil_dr1_host_uuid
            FROM anvils AS anv
            JOIN file_locations AS fil_loc
              ON anv.anvil_uuid = fil_loc.file_location_anvil_uuid
            WHERE fil_loc.file_location_uuid = '${fileLocationUUID}';`,
        ).stdout;

        targetHosts.flat().forEach((hostUUID) => {
          if (hostUUID) {
            anvilSyncSharedFunctions.push(() =>
              dbJobAnvilSyncShared(
                jobName,
                `file_uuid=${fileUUID}`,
                jobTitle,
                jobDescription,
                { jobHostUUID: hostUUID },
              ),
            );
          }
        });
      });
    }

    console.log(`Query (type=[${typeof query}]): [${query}]`);

    let queryStdout;

    try {
      ({ stdout: queryStdout } = dbQuery(query, 'write'));
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
    anvilSyncSharedFunctions.forEach((fn, index) => {
      console.log(
        `Anvil sync shared [${index}] output: [${JSON.stringify(
          fn(),
          null,
          2,
        )}]`,
      );
    });

    response.status(200).send(queryStdout);
  });

module.exports = router;
