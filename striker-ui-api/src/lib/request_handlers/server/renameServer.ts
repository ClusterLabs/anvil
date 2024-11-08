import { buildJobDataFromObject } from '../../buildJobData';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverRenameRequestBodySchema } from './schemas';

export const renameServer = buildServerUpdateHandler<ServerRenameRequestBody>(
  async ({ body }) => {
    serverRenameRequestBodySchema.validateSync(body);
  },
  async ({ body, params }, { uuid: hostUuid }, sbin) => {
    const { uuid: serverUuid } = params;
    const { name: newName } = body;

    const tool = 'anvil-rename-server';

    return {
      file: __filename,
      job_command: sbin[tool].self,
      job_data: buildJobDataFromObject({
        'new-name': newName,
        'server-uuid': serverUuid,
      }),
      job_description: `job_0510`,
      job_host_uuid: hostUuid,
      job_name: `server::${serverUuid}::rename`,
      job_title: `job_0509`,
    };
  },
);
