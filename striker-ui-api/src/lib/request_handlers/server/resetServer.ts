import { buildJobDataFromObject } from '../../buildJobData';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';

export const resetServer = buildServerUpdateHandler(
  null,
  async (request, server, sbin) => ({
    job_command: sbin['anvil-shutdown-server'].self,
    job_data: buildJobDataFromObject({
      'server-uuid': server.uuid,
      task: 'reset',
    }),
    job_description: `job_0339`,
    job_host_uuid: server.host.uuid,
    job_name: `set_power::${server.uuid}::reset`,
    job_title: `job_0338`,
  }),
);
