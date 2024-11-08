import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverAddDiskRequestBodySchema } from './schemas';

export const addServerDisk = buildServerUpdateHandler<ServerAddDiskRequestBody>(
  async ({ body }) => {
    serverAddDiskRequestBodySchema.validateSync(body);
  },
  async ({ body, params }, { uuid: hostUuid }, sbin) => {
    const { uuid: serverUuid } = params;
    const { anvil, size, storage } = body;

    const tool = 'anvil-manage-server-storage';

    let anvilFlag = '';

    if (anvil) {
      anvilFlag = `--anvil ${anvil}`;
    }

    return {
      job_command: `${sbin[tool].self} ${anvilFlag} --server ${serverUuid} --add ${size} --storage-group ${storage}`,
      job_description: `job_0498`,
      job_host_uuid: hostUuid,
      job_name: `server::${serverUuid}::add_disk`,
      job_title: `job_0497`,
    };
  },
);
