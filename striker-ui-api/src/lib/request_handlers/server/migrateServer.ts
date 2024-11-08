import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverMigrateRequestBodySchema } from './schemas';

export const migrateServer = buildServerUpdateHandler<ServerMigrateRequestBody>(
  async ({ body }) => {
    serverMigrateRequestBodySchema.validateSync(body);
  },
  async ({ body, params }, { host }, sbin) => {
    const { uuid: serverUuid } = params;
    const { target } = body;

    const tool = 'anvil-migrate-server';

    return {
      job_command: `${sbin[tool].self} --server-uuid ${serverUuid} --target ${target}`,
      job_description: `job_0512`,
      job_host_uuid: host.uuid,
      job_name: `server::${serverUuid}::migrate`,
      job_title: `job_0511`,
    };
  },
);
