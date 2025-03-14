import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverGrowDiskRequestBodySchema } from './schemas';

export const growServerDisk =
  buildServerUpdateHandler<ServerGrowDiskRequestBody>(
    async ({ body }) => {
      await serverGrowDiskRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { anvil, device, size } = body;

      const tool = 'anvil-manage-server-storage';

      let anvilFlag = '';

      if (anvil) {
        anvilFlag = `--anvil ${anvil}`;
      }

      return {
        job_command: `${sbin[tool].self} ${anvilFlag} --server ${server.uuid} --disk ${device} --grow ${size}`,
        job_description: `job_0500`,
        job_host_uuid: server.host.uuid,
        job_name: `server::${server.uuid}::grow_disk`,
        job_title: `job_0499`,
      };
    },
  );
