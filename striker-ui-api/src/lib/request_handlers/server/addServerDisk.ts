import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverAddDiskRequestBodySchema } from './schemas';

export const addServerDisk = buildServerUpdateHandler<ServerAddDiskRequestBody>(
  async ({ body }) => {
    await serverAddDiskRequestBodySchema.validate(body);
  },
  async ({ body }, server, sbin) => {
    const { anvil, size, storage } = body;

    const tool = 'anvil-manage-server-storage';

    let anvilFlag = '';

    if (anvil) {
      anvilFlag = `--anvil ${anvil}`;
    }

    return {
      job_command: `${sbin[tool].self} ${anvilFlag} --server ${server.uuid} --add ${size} --storage-group ${storage}`,
      job_description: `job_0498`,
      job_host_uuid: server.host.uuid,
      job_name: `server::${server.uuid}::add_disk`,
      job_title: `job_0497`,
    };
  },
);
