import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverGrowDiskRequestBodySchema } from './schemas';

export const growServerDisk =
  buildServerUpdateHandler<ServerGrowDiskRequestBody>(
    async ({ body }) => {
      serverGrowDiskRequestBodySchema.validateSync(body);
    },
    async ({ body, params }, { uuid: hostUuid }, sbin) => {
      const { uuid: serverUuid } = params;
      const { anvil, device, size } = body;

      const tool = 'anvil-manage-server-storage';

      let anvilFlag = '';

      if (anvil) {
        anvilFlag = `--anvil ${anvil}`;
      }

      return {
        job_command: `${sbin[tool].self} ${anvilFlag} --server ${serverUuid} --disk ${device} --grow ${size}`,
        job_description: ``,
        job_host_uuid: hostUuid,
        job_name: `server::${serverUuid}::grow_disk`,
        job_title: `job_0489,!!tool!${tool}!!`,
      };
    },
  );
