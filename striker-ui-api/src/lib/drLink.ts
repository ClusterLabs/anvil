import { SERVER_PATHS } from './consts';

import { job, query } from './accessModule';
import { perr, poutvar } from './shell';
import { sqlDrLinked, sqlDrLinkedFromSg, sqlDrLinkedFromVg } from './sqls';

export const linkDr = async (
  anvilUuid: string,
  drUuid: string,
  link = true,
) => {
  poutvar(
    {
      anvilUuid,
      drUuid,
      link,
    },
    `In linkDr: `,
  );

  // select link or unlink operation

  let operation: 'link' | 'unlink';

  if (link) {
    operation = 'link';
  } else {
    operation = 'unlink';
  }

  const command = SERVER_PATHS.usr.sbin['anvil-manage-dr'].self;

  const commandArgs = [
    `--${operation}`,
    '--dr-host',
    drUuid,
    '--anvil',
    anvilUuid,
  ];

  try {
    await job({
      file: __filename,
      job_command: [command, ...commandArgs].join(' '),
      job_host_uuid: drUuid,
      job_description: 'job_0384',
      job_name: `dr::${operation}`,
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
  options: {
    drUuid?: string;
    link?: boolean;
    lvmVgUuids?: string[];
    sgName?: string;
  } = {},
) => {
  poutvar(
    {
      anvilUuid,
      ...options,
    },
    `In linkDrFrom: `,
  );

  const { drUuid, link = true, lvmVgUuids, sgName } = options;

  // get the current link state of the DR host(s)

  let rows: string[][];

  let sql: string;

  if (drUuid) {
    sql = sqlDrLinked(anvilUuid, `'${drUuid}'`);
  } else if (lvmVgUuids) {
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
