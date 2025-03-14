import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverMigrateRequestBodySchema } from './schemas';

export const migrateServer = buildServerUpdateHandler<ServerMigrateRequestBody>(
  async ({ body }) => {
    await serverMigrateRequestBodySchema.validate(body);
  },
  async ({ body }, server, sbin) => {
    const { target } = body;

    const tool = 'anvil-migrate-server';

    return {
      job_command: `${sbin[tool].self} --server-uuid ${server.uuid} --target ${target}`,
      job_description: `job_0512`,
      job_host_uuid: server.host.uuid,
      job_name: `server::${server.uuid}::migrate`,
      job_title: `job_0511`,
    };
  },
);
