import { buildServerUpdateHandler } from './buildServerUpdateHandler';

export const resetServer = buildServerUpdateHandler(
  null,
  async ({ params }, { host }, sbin) => {
    const { uuid: serverUuid } = params;

    return {
      job_command: `${sbin['anvil-shutdown-server'].self} --reset`,
      job_data: `server_uuid=${serverUuid}`,
      job_description: `job_0339`,
      job_host_uuid: host.uuid,
      job_name: `set_power::${serverUuid}::reset`,
      job_title: `job_0338`,
    };
  },
);
