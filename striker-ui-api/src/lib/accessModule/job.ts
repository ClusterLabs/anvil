import { DEFAULT_JOB_PROGRESS } from '../consts';

import { sub } from './sub';

export const job = async ({
  job_progress = DEFAULT_JOB_PROGRESS,
  line = 0,
  ...rest
}: JobParams) => {
  const [uuid]: [string] = await sub('insert_or_update_jobs', {
    params: [{ job_progress, line, ...rest }],
  });

  return uuid;
};
