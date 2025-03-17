import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverDeleteIfaceRequestBodySchema } from './schemas';

export const deleteServerIface =
  buildServerUpdateHandler<ServerDeleteIfaceRequestBody>(
    async ({ body }) => {
      await serverDeleteIfaceRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { mac } = body;

      const tool = 'anvil-manage-server-network';

      return {
        job_command: `${sbin[tool].self} --server ${server.uuid} --mac ${mac} --remove`,
        job_description: `job_0508`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::delete_interface`,
        job_title: `job_0507`,
      };
    },
  );
