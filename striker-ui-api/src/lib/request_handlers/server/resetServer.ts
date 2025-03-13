import { buildJobDataFromObject } from '../../buildJobData';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';

export const resetServer = buildServerUpdateHandler(
  null,
  async ({ params }, { host }, sbin) => {
    const { uuid: serverUuid } = params;

    return {
      job_command: sbin['anvil-shutdown-server'].self,
      job_data: buildJobDataFromObject({
        server_uuid: serverUuid,
        task: 'reset',
      }),
      job_description: `job_0339`,
      job_host_uuid: host.uuid,
      job_name: `set_power::${serverUuid}::reset`,
      job_title: `job_0338`,
    };
  },
);
