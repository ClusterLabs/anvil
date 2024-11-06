import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetBootOrderRequestBodySchema } from './schemas';

export const setServerBootOrder =
  buildServerUpdateHandler<ServerSetBootOrderRequestBody>(
    async ({ body }) => {
      serverSetBootOrderRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { order } = body;

      const tool = 'anvil-manage-server-system';

      return {
        job_command: `${
          sbin[tool].self
        } --server ${serverUuid} --boot-order ${order.join(',')}`,
        job_description: ``,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::set_boot_order`,
        job_title: `job_0489,!!tool!${tool}!!`,
      };
    },
  );
