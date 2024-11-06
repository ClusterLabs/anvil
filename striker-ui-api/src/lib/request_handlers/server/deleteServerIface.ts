import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverDeleteIfaceRequestBodySchema } from './schemas';

export const deleteServerIface =
  buildServerUpdateHandler<ServerDeleteIfaceRequestBody>(
    async ({ body }) => {
      serverDeleteIfaceRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { mac } = body;

      const tool = 'anvil-manage-server-network';

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} --mac ${mac} --remove`,
        job_description: ``,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::delete_interface`,
        job_title: `job_0489,!!tool!${tool}!!`,
      };
    },
  );
