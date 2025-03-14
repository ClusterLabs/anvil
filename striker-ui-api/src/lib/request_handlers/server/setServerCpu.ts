import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetCpuRequestBodySchema } from './schemas';

export const setServerCpu = buildServerUpdateHandler<ServerSetCpuRequestBody>(
  async ({ body }) => {
    await serverSetCpuRequestBodySchema.validate(body);
  },
  async ({ body }, server, sbin) => {
    const { cores, sockets } = body;

    const tool = 'anvil-manage-server-system';

    return {
      job_command: `${sbin[tool].self} --server ${server.uuid} --cpu ${sockets},${cores}`,
      job_description: `job_0494`,
      job_host_uuid: server.host.uuid,
      job_name: `server::${server.uuid}::set_cpu`,
      job_title: `job_0493`,
    };
  },
);
