import { RequestHandler } from 'express';

import { anvilSyncShared, query, timestamp, write } from '../../accessModule';
import { stderr, stdoutVar } from '../../shell';

export const updateFile: RequestHandler = async (request, response) => {
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
        anvilSyncShared(
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
      anvilSyncShared('check_mode', `file_uuid=${fileUUID}`, '0143', '0144', {
        jobHostUUID: 'all',
      }),
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
              ON fil_loc.file_location_host_uuid IN (
                anv.anvil_node1_host_uuid,
                anv.anvil_node2_host_uuid,
                anv.anvil_dr1_host_uuid
              )
            WHERE fil_loc.file_location_uuid = '${fileLocationUUID}';`,
        );

        targetHosts.flat().forEach((hostUUID: null | string) => {
          if (hostUUID) {
            anvilSyncSharedFunctions.push(() =>
              anvilSyncShared(
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

  let wcode: number;

  try {
    wcode = await write(sqlscript);
  } catch (queryError) {
    stderr(`Failed to execute query; CAUSE: ${queryError}`);

    return response.status(500).send();
  }

  anvilSyncSharedFunctions.forEach(async (fn, index) =>
    stdoutVar(await fn(), `Anvil sync shared [${index}] output: `),
  );

  response.status(200).send(wcode);
};
