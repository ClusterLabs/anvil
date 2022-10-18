import { spawnSync, SpawnSyncOptions } from 'child_process';

import SERVER_PATHS from './consts/SERVER_PATHS';

const execAnvilAccessModule = (
  args: string[],
  options: SpawnSyncOptions = {
    encoding: 'utf-8',
    timeout: 10000,
  },
) => {
  const { error, stdout, stderr } = spawnSync(
    SERVER_PATHS.usr.sbin['anvil-access-module'].self,
    args,
    options,
  );

  if (error) {
    throw error;
  }

  if (stderr.length > 0) {
    throw new Error(stderr.toString());
  }

  let output;

  try {
    output = JSON.parse(stdout.toString());
  } catch (stdoutParseError) {
    output = stdout;

    console.warn(
      `Failed to parse anvil-access-module output [${output}]; CAUSE: [${stdoutParseError}]`,
    );
  }

  return {
    stdout: output,
  };
};

const execModuleSubroutine = (
  subName: string,
  {
    spawnSyncOptions,
    subModuleName,
    subParams,
  }: ExecModuleSubroutineOptions = {},
) => {
  const args = ['--sub', subName];

  // Defaults to "Database" in anvil-access-module.
  if (subModuleName) {
    args.push('--sub-module', subModuleName);
  }

  if (subParams) {
    args.push('--sub-params', JSON.stringify(subParams));
  }

  console.log(
    `...${subModuleName}->${subName} with params: ${JSON.stringify(
      subParams,
      null,
      2,
    )}`,
  );

  const { stdout } = execAnvilAccessModule(args, spawnSyncOptions);

  return {
    stdout: stdout['sub_results'],
  };
};

const dbInsertOrUpdateJob = (options?: ExecModuleSubroutineOptions) =>
  execModuleSubroutine('insert_or_update_jobs', options).stdout;

const dbJobAnvilSyncShared = (
  jobName: string,
  jobData: string,
  jobTitle: string,
  jobDescription: string,
  { jobHostUUID }: DBJobAnvilSyncSharedOptions = { jobHostUUID: undefined },
) => {
  const subParams: {
    file: string;
    line: number;
    job_command: string;
    job_data: string;
    job_name: string;
    job_title: string;
    job_description: string;
    job_host_uuid?: string;
    job_progress: number;
  } = {
    file: __filename,
    line: 0,
    job_command: SERVER_PATHS.usr.sbin['anvil-sync-shared'].self,
    job_data: jobData,
    job_name: `storage::${jobName}`,
    job_title: `job_${jobTitle}`,
    job_description: `job_${jobDescription}`,
    job_progress: 0,
  };

  if (jobHostUUID) {
    subParams.job_host_uuid = jobHostUUID;
  }

  return dbInsertOrUpdateJob({ subParams });
};

const dbQuery = (query: string, options?: SpawnSyncOptions) => {
  // For printing SQL query to debug.
  // process.stdout.write(`${query.replace(/\s+/g, ' ')}\n`);

  return execAnvilAccessModule(['--query', query], options);
};

const dbSubRefreshTimestamp = () =>
  execModuleSubroutine('refresh_timestamp').stdout;

const dbWrite = (query: string, options?: SpawnSyncOptions) =>
  execAnvilAccessModule(['--query', query, '--mode', 'write'], options);

const getAnvilData = (
  dataStruct: AnvilDataStruct,
  { predata, ...spawnSyncOptions }: GetAnvilDataOptions = {},
) =>
  execAnvilAccessModule(
    [
      '--predata',
      JSON.stringify(predata),
      '--data',
      JSON.stringify(dataStruct),
    ],
    spawnSyncOptions,
  ).stdout;

const getLocalHostUUID = () =>
  execModuleSubroutine('host_uuid', {
    subModuleName: 'Get',
  }).stdout;

export {
  dbInsertOrUpdateJob as job,
  dbJobAnvilSyncShared,
  dbQuery,
  dbSubRefreshTimestamp,
  dbWrite,
  getAnvilData,
  getLocalHostUUID,
  execModuleSubroutine as sub,
};
