import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetMemoryRequestBodySchema } from './schemas';

export const setServerMemory =
  buildServerUpdateHandler<ServerSetMemoryRequestBody>(
    async ({ body }) => {
      await serverSetMemoryRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { size } = body;

      const tool = 'anvil-manage-server-system';

      return {
        job_command: `${sbin[tool].self} --server ${server.uuid} --ram ${size}`,
        job_description: `job_0496`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::set_memory`,
        job_title: `job_0495`,
      };
    },
  );
