import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetBootOrderRequestBodySchema } from './schemas';

export const setServerBootOrder =
  buildServerUpdateHandler<ServerSetBootOrderRequestBody>(
    async ({ body }) => {
      await serverSetBootOrderRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { order } = body;

      const tool = 'anvil-manage-server-system';

      return {
        job_command: `${sbin[tool].self} --server ${
          server.uuid
        } --boot-order ${order.join(',')}`,
        job_description: `job_0492`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::set_boot_order`,
        job_title: `job_0491`,
      };
    },
  );
