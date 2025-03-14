import { buildJobDataFromObject } from '../../buildJobData';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverRenameRequestBodySchema } from './schemas';

export const renameServer = buildServerUpdateHandler<ServerRenameRequestBody>(
  async ({ body }) => {
    await serverRenameRequestBodySchema.validate(body);
  },
  async ({ body }, server, sbin) => {
    const { name: newName } = body;

    const tool = 'anvil-rename-server';

    return {
      file: __filename,
      job_command: sbin[tool].self,
      job_data: buildJobDataFromObject({
        'new-name': newName,
        'server-uuid': server.uuid,
      }),
      job_description: `job_0510`,
      job_host_uuid: server.host.uuid,
      job_name: `server::${server.uuid}::rename`,
      job_title: `job_0509`,
    };
  },
);
