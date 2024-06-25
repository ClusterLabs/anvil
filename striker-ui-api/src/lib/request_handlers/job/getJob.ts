import { RequestHandler } from 'express';

import { query, translate } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { ResponseError } from '../../ResponseError';
import { sanitize } from '../../sanitize';
import { date, perr } from '../../shell';

export const getJob: RequestHandler<
  undefined,
  JobOverviewList | ResponseErrorBody,
  undefined,
  JobRequestQuery
> = async (request, response) => {
  const {
    query: { start: rStart, command: rCommand },
  } = request;

  // Expects EPOCH in seconds
  const start = sanitize(rStart, 'number');
  const jcmd = sanitize(rCommand, 'string', { modifierType: 'sql' });

  let condModified = 'OR a.job_progress = 100';

  if (start >= 0) {
    try {
      const minDate = date('--date', `@${start}`, '--rfc-3339', 'ns');

      condModified = `OR (a.job_progress = 100 AND a.modified_date >= '${minDate}')`;
    } catch (error) {
      // Ignore; just include all jobs
    }
  }

  let condCommand = '';

  if (jcmd) {
    condCommand = `AND a.job_command LIKE '%${jcmd}%'`;
  }

  const sql = `
    SELECT
      a.job_uuid,
      a.job_name,
      a.job_title,
      a.job_host_uuid,
      b.host_name,
      a.job_progress,
      a.job_picked_up_at
    FROM jobs AS a
    JOIN hosts AS b
      ON a.job_host_uuid = b.host_uuid
    WHERE (a.job_progress < 100 ${condModified})
      ${condCommand}
      AND a.job_name NOT LIKE 'get_server_screenshot%'
    ORDER BY a.modified_date DESC;`;

  let rows: string[][];

  try {
    rows = await query<string[][]>(sql);
  } catch (error) {
    const rserror = new ResponseError(
      'c2b683b',
      `Failed to get jobs; CAUSE: ${error}`,
    );

    perr(rserror.toString());

    return response.status(500).send(rserror.body);
  }

  const promises = rows.map<Promise<JobOverview>>(async (row) => {
    const [uuid, name, rTitle, hostUuid, hostName, rProgress, pickedUpAt] = row;

    const hostShortName = getShortHostName(hostName);

    const title = await translate(rTitle);

    return {
      host: {
        name: hostName,
        shortName: hostShortName,
        uuid: hostUuid,
      },
      name,
      progress: Number(rProgress),
      started: Number(pickedUpAt),
      title,
      uuid: uuid,
    };
  });

  const overviews = await Promise.all(promises);

  const rsbody = overviews.reduce<JobOverviewList>((previous, overview) => {
    const { uuid } = overview;

    previous[uuid] = overview;

    return previous;
  }, {});

  return response.status(200).send(rsbody);
};
