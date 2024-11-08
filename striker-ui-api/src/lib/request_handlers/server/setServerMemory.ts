import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetMemoryRequestBodySchema } from './schemas';

export const setServerMemory =
  buildServerUpdateHandler<ServerSetMemoryRequestBody>(
    async ({ body }) => {
      serverSetMemoryRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { host }, sbin) => {
      const { uuid: serverUuid } = params;
      const { size } = body;

      const tool = 'anvil-manage-server-system';

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} --ram ${size}`,
        job_description: `job_0496`,
        job_host_uuid: host.uuid,
        job_name: `server::${serverUuid}::set_memory`,
        job_title: `job_0495`,
      };
    },
  );
