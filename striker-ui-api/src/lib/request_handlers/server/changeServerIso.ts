import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverChangeIsoRequestBodySchema } from './schemas';

export const changeServerIso =
  buildServerUpdateHandler<ServerChangeIsoRequestBody>(
    async ({ body }) => {
      serverChangeIsoRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { anvil, device, iso } = body;

      const tool = 'anvil-manage-server-storage';

      let anvilFlag = '';

      if (anvil) {
        anvilFlag = `--anvil ${anvil}`;
      }

      let isoFlag = '--eject';

      if (iso) {
        isoFlag = `--insert ${iso}`;
      }

      return {
        job_command: `${sbin[tool].self} ${anvilFlag} --server ${serverUuid} --optical ${device} ${isoFlag}`,
        job_description: `job_0502`,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::change_iso`,
        job_title: `job_0501`,
      };
    },
  );
