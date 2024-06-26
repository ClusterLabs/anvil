import { RequestHandler } from 'express';

import { query, translate } from '../../accessModule';
import { cname } from '../../cname';
import { getShortHostName } from '../../disassembleHostName';
import { ResponseError } from '../../ResponseError';
import { sanitize } from '../../sanitize';
import { date, perr, poutvar } from '../../shell';

const JMINTS = 'jmints';

export const getJob: RequestHandler<
  unknown,
  JobOverviewList | ResponseErrorBody,
  unknown,
  JobRequestQuery
> = async (request, response) => {
  const {
    query: { start: rStart, command: rCommand },
  } = request;

  /**
   * - Expects EPOCH in seconds
   * - Fallback to `-1` because `0` is valid
   */
  const start = sanitize(rStart, 'number', { fallback: -1 });
  const jcmd = sanitize(rCommand, 'string', { modifierType: 'sql' });

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
    // Find the oldest incomplete job at the time of the request.
    const sql = `
      SELECT modified_date
      FROM jobs
      WHERE job_progress < 100
      ORDER BY modified_date ASC
      LIMIT 1;`;

    let rows: string[][];

    try {
      rows = await query<[[string]]>(sql);
    } catch (error) {
      const rserror = new ResponseError(
        '6232684',
        `Failed to get oldest in-progress job; CAUSE: ${error}`,
      );

      return response.status(500).send(rserror.body);
    }

    const cn = cname('session');
    /**
     * Make a shallow copy of the session cookie.
     *
     * Note: request.cookies is populated by middleware 'cookie-parser'.
     */
    const session = { ...request.cookies[cn] };

    poutvar(session, `Session cookie (before): `);

    if (session && session[JMINTS]) {
      // Use the mints from a previous fetch if there's one.

      conditions = `a.modified_date >= '${session[JMINTS]}'`;
    } else if (rows.length > 0) {
      // Use fresh mints on the first fetch in current session.

      conditions = `a.modified_date >= '${rows[0][0]}'`;
    } else {
      // 1. no incomplete job seen in current session,
      // 2. no incomplete during this fetch
      // So just get recent jobs.

      conditions = `a.modified_date >= NOW() - INTERVAL '1 hour'`;
    }

    if (rows.length > 0) {
      // If there's an incomplete job from this fetch, record the mints.

      session[JMINTS] = rows[0][0];
    } else {
      // If there's no incomplete job from this fetch, remove the mints.

      delete session[JMINTS];
    }

    poutvar(session, `Session cookie (after): `);

    response.cookie(cn, session);
  }

  if (jcmd) {
    conditions = `${conditions} AND a.job_command LIKE '%${jcmd}%'`;
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
    const rserror = new ResponseError(
      'c2b683b',
      `Failed to get jobs; CAUSE: ${error}`,
    );

    perr(rserror.toString());

    return response.status(500).send(rserror.body);
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

  const rsbody = overviews.reduce<JobOverviewList>((previous, overview) => {
    const { uuid } = overview;

    previous[uuid] = overview;

    return previous;
  }, {});

  return response.status(200).send(rsbody);
};
