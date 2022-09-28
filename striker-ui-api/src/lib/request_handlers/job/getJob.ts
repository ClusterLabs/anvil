import { sanitizeQS } from '../../sanitizeQS';
import { date } from '../../shell';
import buildGetRequestHandler from '../buildGetRequestHandler';

export const getJob = buildGetRequestHandler((request, buildQueryOptions) => {
  const { epoch } = request.query;

  const sanitizedEpoch = sanitizeQS(epoch, { returnType: 'number' });

  let condModifiedDate = '';

  try {
    const minDate = date('--date', `@${sanitizedEpoch}`, '--rfc-3339', 'ns');

    condModifiedDate = `OR (job.job_progress = 100 AND job.modified_date >= '${minDate}')`;
  } catch (shellError) {
    throw new Error(
      `Failed to build date condition for job query; CAUSE: ${shellError}`,
    );
  }

  process.stdout.write(`condModifiedDate=[${condModifiedDate}]\n`);

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
    WHERE job.job_progress < 100
      ${condModifiedDate};`;
});
