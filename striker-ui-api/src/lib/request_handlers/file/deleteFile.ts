import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { anvilSyncShared, query, timestamp, write } from '../../accessModule';

export const deleteFile: RequestHandler = async (request, response) => {
  const { fileUUID } = request.params;

  const [[oldFileType]] = await query(
    `SELECT file_type FROM files WHERE file_uuid = '${fileUUID}';`,
  );

  if (oldFileType !== DELETED) {
    await write(
      `UPDATE files
          SET
            file_type = '${DELETED}',
            modified_date = '${timestamp()}'
          WHERE file_uuid = '${fileUUID}';`,
    );

    await anvilSyncShared('purge', `file_uuid=${fileUUID}`, '0136', '0137', {
      jobHostUUID: 'all',
    });
  }

  response.status(204).send();
};
