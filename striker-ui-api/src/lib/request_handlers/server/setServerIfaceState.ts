import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetIfaceStateRequestBodySchema } from './schemas';

export const setServerIfaceState =
  buildServerUpdateHandler<ServerSetIfaceStateRequestBody>(
    async ({ body }) => {
      await serverSetIfaceStateRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { active, mac } = body;

      const tool = 'anvil-manage-server-network';

      let stateFlag = '--unplug';

      if (active) {
        stateFlag = '--plug';
      }

      return {
        job_command: `${sbin[tool].self} --server ${server.uuid} --mac ${mac} ${stateFlag}`,
        job_description: `job_0506`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::set_interface_state`,
        job_title: `job_0505`,
      };
    },
  );
