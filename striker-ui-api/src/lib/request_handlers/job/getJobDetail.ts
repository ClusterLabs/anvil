import { RequestHandler } from 'express';

import { query, translate } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { ResponseError } from '../../ResponseError';
import { poutvar } from '../../shell';

/**
 * Removes empty elements from the start of the given string array.
 * @param strings - string array
 * @returns modifed string array
 */
const trimStart = (strings: string[]): string[] => {
  let count = 0;

  strings.some((string) => {
    if (string.length > 0) return true;

    count += 1;

    return false;
  });

  strings.splice(0, count);

  return strings;
};

export const getJobDetail: RequestHandler<
  JobParamsDictionary,
  JobDetail | ResponseErrorBody
> = async (request, response) => {
  const {
    params: { uuid: jobUuid },
  } = request;

  const sql = `
    SELECT
      a.job_uuid,
      a.job_command,
      a.job_data,
      a.job_picked_up_by,
      a.job_picked_up_at,
      a.job_updated,
      a.job_name,
      a.job_progress,
      a.job_title,
      a.job_description,
      a.job_status,
      ROUND(
        EXTRACT(epoch from a.modified_date)
      ) AS modified_epoch,
      b.host_uuid,
      b.host_name
    FROM jobs AS a
    JOIN hosts AS b
      ON a.job_host_uuid = b.host_uuid
    WHERE a.job_uuid = '${jobUuid}';`;

  let rows: string[][];

  try {
    rows = await query<string[][]>(sql);
  } catch (error) {
    const rserror = new ResponseError(
      '249068d',
      `Failed to get job ${jobUuid}; CAUSE: ${error}`,
    );

    return response.status(500).send(rserror.body);
  }

  if (!rows.length) {
    const rserror = new ResponseError(
      'b4e559c',
      `No job found with identifier ${jobUuid}`,
    );

    return response.status(404).send(rserror.body);
  }

  const [row] = rows;

  const [
    uuid,
    command,
    rData,
    pickedUpBy,
    pickedUpAt,
    updated,
    name,
    progress,
    rTitle,
    rDescription,
    rStatus,
    modified,
    hostUuid,
    hostName,
  ] = row;

  const title = await translate(rTitle);
  const description = await translate(rDescription);

  const hostShortName = getShortHostName(hostName);

  const dataLines = trimStart(rData.split(/,|\n/));
  const data = dataLines.reduce<JobDetail['data']>((previous, entry, index) => {
    const [name, value] = entry.split(/=/);

    previous[index] = { name, value };

    return previous;
  }, {});

  /**
   * List of word key prefixes generated with:
   *
   * grep -o '<key.*name="[^_]\+' words.xml | cut -c 12- | sort | uniq | paste -sd '|'
   */
  const rStatusLines = trimStart(
    rStatus.split(
      /(?=(?:brand|email|error|file|header|job|log|message|name|ok|prefix|striker|suffix|t|title|type|unit|ups|warning)_\d{4,})/g,
    ),
  );
  const promises = rStatusLines.map<Promise<JobStatus>>(async (line) => ({
    value: await translate(line.trim()),
  }));
  const statusLines = await Promise.all(promises);
  const status = statusLines.reduce<JobDetail['status']>(
    (previous, s, index) => {
      previous[index] = s;

      return previous;
    },
    {},
  );

  poutvar({
    dataLines,
    data,
    rStatusLines,
    statusLines,
    status,
  });

  const rsbody: JobDetail = {
    command,
    data,
    description,
    host: {
      name: hostName,
      shortName: hostShortName,
      uuid: hostUuid,
    },
    modified: Number(modified),
    name,
    pid: Number(pickedUpBy),
    progress: Number(progress),
    started: Number(pickedUpAt),
    status,
    title,
    updated: Number(updated),
    uuid,
  };

  return response.status(200).send(rsbody);
};
