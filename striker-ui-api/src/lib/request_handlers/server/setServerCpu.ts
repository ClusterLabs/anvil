import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetCpuRequestBodySchema } from './schemas';

export const setServerCpu = buildServerUpdateHandler<ServerSetCpuRequestBody>(
  async ({ body }) => {
    await serverSetCpuRequestBodySchema.validate(body);
  },
  async ({ body, params }, { host }, sbin) => {
    const { uuid: serverUuid } = params;
    const { cores, sockets } = body;

    const tool = 'anvil-manage-server-system';

    return {
      job_command: `${sbin[tool].self} --server ${serverUuid} --cpu ${sockets},${cores}`,
      job_description: `job_0494`,
      job_host_uuid: host.uuid,
      job_name: `server::${serverUuid}::set_cpu`,
      job_title: `job_0493`,
    };
  },
);
