import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetStartDependencyRequestBodySchema } from './schemas';

export const setServerStartDependency =
  buildServerUpdateHandler<ServerSetStartDependencyRequestBody>(
    async ({ body }) => {
      serverSetStartDependencyRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { active, after, delay } = body;

      let stayOff = '';

      if (active !== undefined && !active) {
        stayOff = 'stay-off';
      }

      const bootAfterFlag = `--boot-after ${after || stayOff || 'none'}`;

      let delayFlag = '';

      if (delay) {
        delayFlag = `--delay ${delay}`;
      }

      const tool = 'anvil-manage-server';

      return {
        job_command: `${sbin[tool].self} --server ${serverUuid} ${bootAfterFlag} ${delayFlag}`,
        job_description: `job_0490`,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::set_start_dependency`,
        job_title: `job_0489`,
      };
    },
  );
