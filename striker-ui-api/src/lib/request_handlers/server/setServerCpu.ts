import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetCpuRequestBodySchema } from './schemas';

export const setServerCpu = buildServerUpdateHandler<ServerSetCpuRequestBody>(
  async ({ body }) => {
    serverSetCpuRequestBodySchema.validateSync(body);
  },
  async ({ body, params }, { uuid: hostUuid }, sbin) => {
    const { uuid: serverUuid } = params;
    const { cores, sockets } = body;

    const tool = 'anvil-manage-server-system';

    return {
      job_command: `${sbin[tool].self} --server ${serverUuid} --cpu ${sockets},${cores}`,
      job_description: ``,
      job_host_uuid: hostUuid,
      job_name: `server::${serverUuid}::set_cpu`,
      job_title: `job_0489,!!tool!${tool}!!`,
    };
  },
);
