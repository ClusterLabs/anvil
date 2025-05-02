import { SERVER_PATHS } from './consts';

import { job, query } from './accessModule';
import { buildJobDataFromObject } from './buildJobData';
import { perr } from './shell';
import { sqlDrLinkedFromSg, sqlDrLinkedFromVg } from './sqls';

export const linkDr = async (
  anvilUuid: string,
  drUuid: string,
  link = true,
) => {
  // select link or unlink operation

  let operation: 'link' | 'unlink';

  if (link) {
    operation = 'link';
  } else {
    operation = 'unlink';
  }

  try {
    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-manage-dr'].self,
      job_data: buildJobDataFromObject({
        [operation]: 1,
        'dr-host': drUuid,
        anvil: anvilUuid,
      }),
      job_name: `dr::${operation}`,
      job_description: 'job_0384',
      job_title: 'job_0385',
    });
  } catch (error) {
    perr(`Failed to set DR host link state; CAUSE: ${error}`);

    throw error;
  }
};

export const unlinkDr = async (
  ...[anvilUuid, drUuid, link = false]: Parameters<typeof linkDr>
) => linkDr(anvilUuid, drUuid, link);

export const linkDrFrom = async (
  anvilUuid: string,
  {
    link = true,
    lvmVgUuids,
    sgName,
  }: {
    link?: boolean;
    lvmVgUuids?: string[];
    sgName?: string;
  } = {},
) => {
  // get the current link state of the DR host(s)

  let rows: string[][];

  let sql: string;

  if (lvmVgUuids) {
    sql = sqlDrLinkedFromVg(anvilUuid, lvmVgUuids);
  } else if (sgName) {
    sql = sqlDrLinkedFromSg(anvilUuid, sgName, 'name');
  } else {
    return;
  }

  try {
    rows = await query(sql);
  } catch (error) {
    perr(`Failed to get DR host link state; CAUSE: ${error}`);

    throw error;
  }

  // link the DR host(s) as needed

  for (const row of rows) {
    const [uuid] = row;

    const linked = Boolean(row[1]);
    const members = Number(row[2]);

    if (link === linked || (!link && members)) {
      continue;
    }

    linkDr(anvilUuid, uuid, link);
  }
};

export const unlinkDrFrom = async (
  ...[anvilUuid, options]: Parameters<typeof linkDrFrom>
) =>
  linkDrFrom(anvilUuid, {
    ...options,
    link: false,
  });
