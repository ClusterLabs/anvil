import { REP_PEACEFUL_STRING } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { sanitize } from '../../sanitize';
import { date, pout } from '../../shell';

export const getJob = buildGetRequestHandler((request, buildQueryOptions) => {
  const { start: rStart, command: rCommand } = request.query;

  const start = sanitize(rStart, 'number');
  const jcmd = sanitize(rCommand, 'string');

  let condModifiedDate = '';

  try {
    const minDate = date('--date', `@${start}`, '--rfc-3339', 'ns');

    condModifiedDate = `OR (job.job_progress = 100 AND job.modified_date >= '${minDate}')`;
  } catch (shellError) {
    throw new Error(
      `Failed to build date condition for job query; CAUSE: ${shellError}`,
    );
  }

  let condJobCommand = '';

  if (REP_PEACEFUL_STRING.test(jcmd)) {
    condJobCommand = `AND job.job_command LIKE '%${jcmd}%'`;
  }

  pout(`condModifiedDate=[${condModifiedDate}]`);

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = (queryStdout) => {
      let result = queryStdout;

      if (queryStdout instanceof Array) {
        result = queryStdout.reduce<{
          [jobUUID: string]: {
            jobCommand: string;
            jobHostName: string;
            jobHostUUID: string;
            jobName: string;
            jobProgress: number;
            jobUUID: string;
          };
        }>(
          (
            previous,
            [
              jobUUID,
              jobName,
              jobHostUUID,
              jobHostName,
              jobCommand,
              rawJobProgress,
            ],
          ) => {
            previous[jobUUID] = {
              jobCommand,
              jobHostName,
              jobHostUUID,
              jobName,
              jobProgress: parseFloat(rawJobProgress),
              jobUUID,
            };

            return previous;
          },
          {},
        );
      }

      return result;
    };
  }

  return `
    SELECT
      job.job_uuid,
      job.job_name,
      job.job_host_uuid,
      hos.host_name,
      job.job_command,
      job.job_progress
    FROM jobs AS job
    JOIN hosts AS hos
      ON job.job_host_uuid = hos.host_uuid
    WHERE (job.job_progress < 100 ${condModifiedDate})
      ${condJobCommand}
      AND job_name NOT LIKE 'get_server_screenshot%';`;
});
