import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverAddIfaceRequestBodySchema } from './schemas';

export const addServerIface =
  buildServerUpdateHandler<ServerAddIfaceRequestBody>(
    async ({ body }) => {
      serverAddIfaceRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { bridge, mac, model } = body;

      const tool = 'anvil-manage-server-network';

      let macFlag = '';

      if (mac) {
        macFlag = `--mac ${mac}`;
      }

      let modelFlag = '';

      if (model) {
        modelFlag = `--model ${model}`;
      }

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} --add --bridge ${bridge} ${macFlag} ${modelFlag}`,
        job_description: ``,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::add_interface`,
        job_title: `job_0489,!!tool!${tool}!!`,
      };
    },
  );
