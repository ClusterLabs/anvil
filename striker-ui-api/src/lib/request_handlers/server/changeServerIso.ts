import path from 'path';

import { query } from '../../accessModule';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverChangeIsoRequestBodySchema } from './schemas';

export const changeServerIso =
  buildServerUpdateHandler<ServerChangeIsoRequestBody>(
    async ({ body }) => {
      await serverChangeIsoRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { anvil, device, iso: fileUuid } = body;

      const tool = 'anvil-manage-server-storage';

      let anvilFlag = '';

      if (anvil) {
        anvilFlag = `--anvil ${anvil}`;
      }

      let isoFlag = '--eject';

      if (fileUuid) {
        const [[filePath]] = await query(`
          SELECT CONCAT(file_directory, '${path.sep}', file_name)
          FROM files
          WHERE file_uuid = '${fileUuid}';`);

        isoFlag = `--insert ${filePath}`;
      }

      return {
        job_command: `${sbin[tool].self} ${anvilFlag} --server ${server.uuid} --optical ${device} ${isoFlag}`,
        job_description: `job_0502`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::change_iso`,
        job_title: `job_0501`,
      };
    },
  );
