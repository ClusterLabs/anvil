import express from 'express';

import { DELETED } from '../lib/consts';

import {
  dbJobAnvilSyncShared,
  timestamp,
  dbWrite,
  query,
} from '../lib/accessModule';
import getFile from '../lib/request_handlers/file/getFile';
import getFileDetail from '../lib/request_handlers/file/getFileDetail';
import uploadSharedFiles from '../middlewares/uploadSharedFiles';
import { stderr, stdout, stdoutVar } from '../lib/shell';

const router = express.Router();

router
  .delete('/:fileUUID', async (request, response) => {
    const { fileUUID } = request.params;

    const [[oldFileType]] = await query(
      `SELECT file_type FROM files WHERE file_uuid = '${fileUUID}';`,
    );

    if (oldFileType !== DELETED) {
      dbWrite(
        `UPDATE files
          SET
            file_type = '${DELETED}',
            modified_date = '${timestamp()}'
          WHERE file_uuid = '${fileUUID}';`,
      ).stdout;

      dbJobAnvilSyncShared('purge', `file_uuid=${fileUUID}`, '0136', '0137', {
        jobHostUUID: 'all',
      });
    }

    response.status(204).send();
  })
  .get('/', getFile)
  .get('/:fileUUID', getFileDetail)
  .post('/', uploadSharedFiles.single('file'), ({ file, body }, response) => {
    stdout('Receiving shared file.');

    if (file) {
      stdoutVar({ body, file });

      dbJobAnvilSyncShared(
        'move_incoming',
        `file=${file.path}`,
        '0132',
        '0133',
      );

      response.status(200).send();
    }
  })
  .put('/:fileUUID', async (request, response) => {
    const { body = {}, params } = request;

    stdoutVar(body, 'Begin edit single file. body=');

    const { fileUUID } = params;
    const { fileName, fileLocations, fileType } = body;
    const anvilSyncSharedFunctions = [];

    let sqlscript = '';

    if (fileName) {
      const [[oldFileName]] = await query(
        `SELECT file_name FROM files WHERE file_uuid = '${fileUUID}';`,
      );

      stdoutVar({ oldFileName, fileName });

      if (fileName !== oldFileName) {
        sqlscript += `
          UPDATE files
          SET
            file_name = '${fileName}',
            modified_date = '${timestamp()}'
          WHERE file_uuid = '${fileUUID}';`;

        anvilSyncSharedFunctions.push(() =>
          dbJobAnvilSyncShared(
            'rename',
            `file_uuid=${fileUUID}\nold_name=${oldFileName}\nnew_name=${fileName}`,
            '0138',
            '0139',
            { jobHostUUID: 'all' },
          ),
        );
      }
    }

    if (fileType) {
      sqlscript += `
        UPDATE files
        SET
          file_type = '${fileType}',
          modified_date = '${timestamp()}'
        WHERE file_uuid = '${fileUUID}';`;

      anvilSyncSharedFunctions.push(() =>
        dbJobAnvilSyncShared(
          'check_mode',
          `file_uuid=${fileUUID}`,
          '0143',
          '0144',
          { jobHostUUID: 'all' },
        ),
      );
    }

    if (fileLocations) {
      fileLocations.forEach(
        async ({
          fileLocationUUID,
          isFileLocationActive,
        }: {
          fileLocationUUID: string;
          isFileLocationActive: boolean;
        }) => {
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

          sqlscript += `
            UPDATE file_locations
            SET
              file_location_active = '${fileLocationActive}',
              modified_date = '${timestamp()}'
            WHERE file_location_uuid = '${fileLocationUUID}';`;

          const targetHosts: [
            n1uuid: string,
            n2uuid: string,
            dr1uuid: null | string,
          ][] = await query(
            `SELECT
              anv.anvil_node1_host_uuid,
              anv.anvil_node2_host_uuid,
              anv.anvil_dr1_host_uuid
            FROM anvils AS anv
            JOIN file_locations AS fil_loc
              ON anv.anvil_uuid = fil_loc.file_location_anvil_uuid
            WHERE fil_loc.file_location_uuid = '${fileLocationUUID}';`,
          );

          targetHosts.flat().forEach((hostUUID: null | string) => {
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
        },
      );
    }

    stdout(`Query (type=[${typeof sqlscript}]): [${sqlscript}]`);

    let queryStdout;

    try {
      ({ stdout: queryStdout } = dbWrite(sqlscript));
    } catch (queryError) {
      stderr(`Failed to execute query; CAUSE: ${queryError}`);

      return response.status(500).send();
    }

    stdoutVar(queryStdout, `Query stdout (type=[${typeof queryStdout}]): `);

    anvilSyncSharedFunctions.forEach((fn, index) =>
      stdoutVar(fn(), `Anvil sync shared [${index}] output: `),
    );

    response.status(200).send(queryStdout);
  });

export default router;
