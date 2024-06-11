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

    condModifiedDate = `OR (a.job_progress = 100 AND a.modified_date >= '${minDate}')`;
  } catch (shellError) {
    throw new Error(
      `Failed to build date condition for job query; CAUSE: ${shellError}`,
    );
  }

  let condJobCommand = '';

  if (REP_PEACEFUL_STRING.test(jcmd)) {
    condJobCommand = `AND a.job_command LIKE '%${jcmd}%'`;
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
      a.job_uuid,
      a.job_name,
      a.job_host_uuid,
      b.host_name,
      a.job_command,
      a.job_progress
    FROM jobs AS a
    JOIN hosts AS b
      ON a.job_host_uuid = b.host_uuid
    WHERE (a.job_progress < 100 ${condModifiedDate})
      ${condJobCommand}
      AND job_name NOT LIKE 'get_server_screenshot%';`;
});
