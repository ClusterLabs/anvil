import { SERVER_PATHS } from '../consts';

import { job } from './job';

export const anvilSyncShared = (
  jobName: string,
  jobData: string,
  jobTitle: string,
  jobDescription: string,
  { jobHostUUID }: JobAnvilSyncSharedOptions = { jobHostUUID: undefined },
) => {
  const subParams: JobParams = {
    file: __filename,
    job_command: SERVER_PATHS.usr.sbin['anvil-sync-shared'].self,
    job_data: jobData,
    job_name: `storage::${jobName}`,
    job_title: `job_${jobTitle}`,
    job_description: `job_${jobDescription}`,
  };

  if (jobHostUUID) {
    subParams.job_host_uuid = jobHostUUID;
  }

  return job(subParams);
};
