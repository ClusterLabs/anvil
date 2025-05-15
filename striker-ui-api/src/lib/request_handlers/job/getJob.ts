import { RequestHandler } from 'express';

import { query, translate } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { Responder } from '../../Responder';
import { getJobQueryStringSchema } from './schemas';
import { date, perr } from '../../shell';

export const getJob: RequestHandler<
  unknown,
  JobOverviewList | ResponseErrorBody,
  unknown,
  JobRequestQuery
> = async (request, response) => {
  const respond = new Responder(response);

  let qs: {
    command?: string[];
    name?: string[];
    // Expects EPOCH in seconds
    start: number;
  };

  try {
    qs = await getJobQueryStringSchema.validate(request.query);
  } catch (error) {
    return respond.s400(
      '7216e1d',
      `Invalid request query string(s); CAUSE: ${error}`,
    );
  }

  const { command: lsCommand, name: lsName, start } = qs;

  // Start with boundless value and replace when needed.
  let conditions = 'TRUE';

  if (start >= 0) {
    try {
      const mints = date('--date', `@${start}`, '--rfc-3339', 'ns');

      conditions = `a.modified_date >= '${mints}'`;
    } catch (error) {
      perr(
        `Failed to convert value [${start}] to rfc-3339 format; CAUSE: ${error}`,
      );
    }
  } else {
    // Use modified_date of the oldest incomplete job as mints.
    // Use a "recent" timestamp when there aren't incomplete jobs.
    conditions = `
      a.modified_date >= (
        LEAST(
          (
            SELECT modified_date
            FROM jobs
            WHERE job_progress < 100
            ORDER BY modified_date ASC
            LIMIT 1
          ),
          NOW() - INTERVAL '1 hour'
        )
      )`;
  }

  if (lsCommand) {
    conditions += join(lsCommand, {
      beforeReturn: (csv) =>
        csv && ` AND a.job_command LIKE ANY (ARRAY[${csv}])`,
      onEach: (value) => `'%${value}%'`,
      separator: ', ',
    });
  }

  if (lsName) {
    conditions += join(lsName, {
      beforeReturn: (csv) => csv && `  AND a.job_name LIKE ANY (ARRAY[${csv}])`,
      onEach: (value) => `'%${value}%'`,
      separator: ', ',
    });
  }

  const sql = `
    SELECT
      a.job_uuid,
      a.job_name,
      a.job_title,
      b.host_uuid,
      b.host_name,
      a.job_progress,
      a.job_picked_up_at,
      ROUND(
        EXTRACT(epoch from a.modified_date)
      ) AS modified_epoch
    FROM jobs AS a
    JOIN hosts AS b
      ON a.job_host_uuid = b.host_uuid
    WHERE ${conditions}
      AND a.job_name NOT LIKE 'get_server_screenshot%'
    ORDER BY a.modified_date DESC;`;

  let rows: string[][];

  try {
    rows = await query<string[][]>(sql);
  } catch (error) {
    return respond.s500('c2b683b', `Failed to get jobs; CAUSE: ${error}`);
  }

  const promises = rows.map<Promise<JobOverview>>(async (row) => {
    const [
      uuid,
      name,
      rTitle,
      hostUuid,
      hostName,
      rProgress,
      pickedUpAt,
      modified,
    ] = row;

    const hostShortName = getShortHostName(hostName);

    const title = await translate(rTitle);

    return {
      host: {
        name: hostName,
        shortName: hostShortName,
        uuid: hostUuid,
      },
      modified: Number(modified),
      name,
      progress: Number(rProgress),
      started: Number(pickedUpAt),
      title,
      uuid: uuid,
    };
  });

  const overviews = await Promise.all(promises);

  const body = overviews.reduce<JobOverviewList>((previous, overview) => {
    const { uuid } = overview;

    previous[uuid] = overview;

    return previous;
  }, {});

  return respond.s200(body);
};
