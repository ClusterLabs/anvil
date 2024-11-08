import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverDeleteIfaceRequestBodySchema } from './schemas';

export const deleteServerIface =
  buildServerUpdateHandler<ServerDeleteIfaceRequestBody>(
    async ({ body }) => {
      serverDeleteIfaceRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { host }, sbin) => {
      const { uuid: serverUuid } = params;
      const { mac } = body;

      const tool = 'anvil-manage-server-network';

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} --mac ${mac} --remove`,
        job_description: `job_0508`,
        job_host_uuid: host.uuid,
        job_name: `server::${serverUuid}::delete_interface`,
        job_title: `job_0507`,
      };
    },
  );
