import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetIfaceStateRequestBodySchema } from './schemas';

export const setServerIfaceState =
  buildServerUpdateHandler<ServerSetIfaceStateRequestBody>(
    async ({ body }) => {
      serverSetIfaceStateRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { active, mac } = body;

      const tool = 'anvil-manage-server-network';

      let stateFlag = '--unplug';

      if (active) {
        stateFlag = '--plug';
      }

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} --mac ${mac} ${stateFlag}`,
        job_description: `job_0506`,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::set_interface_state`,
        job_title: `job_0505`,
      };
    },
  );
