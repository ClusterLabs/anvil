import { spawnSync, SpawnSyncOptions } from 'child_process';

import SERVER_PATHS from './consts/SERVER_PATHS';

const execStrikerAccessDatabase = (
  args: string[],
  options: SpawnSyncOptions = {
    timeout: 10000,
    encoding: 'utf-8',
  },
) => {
  const { error, stdout, stderr } = spawnSync(
    SERVER_PATHS.usr.sbin['striker-access-database'].self,
    args,
    options,
  );

  if (error) {
    throw error;
  }

  if (stderr) {
    throw new Error(stderr.toString());
  }

  let output;

  try {
    output = JSON.parse(stdout.toString());
  } catch (stdoutParseError) {
    output = stdout;

    console.warn(
      `Failed to parse striker-access-database output [${output}]; error: [${stdoutParseError}]`,
    );
  }

  return {
    stdout: output,
  };
};

const execDatabaseModuleSubroutine = (
  subName: string,
  subParams?: Record<string, unknown>,
  options?: SpawnSyncOptions,
) => {
  const args = ['--sub', subName];

  if (subParams) {
    args.push('--sub-params', JSON.stringify(subParams));
  }

  const { stdout } = execStrikerAccessDatabase(args, options);

  return {
    stdout: stdout['sub_results'],
  };
};

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

  console.log(JSON.stringify(subParams, null, 2));

  return execDatabaseModuleSubroutine('insert_or_update_jobs', subParams)
    .stdout;
};

const dbQuery = (query: string, options?: SpawnSyncOptions) =>
  execStrikerAccessDatabase(['--query', query], options);

const dbSubRefreshTimestamp = () =>
  execDatabaseModuleSubroutine('refresh_timestamp').stdout;

const dbWrite = (query: string, options?: SpawnSyncOptions) =>
  execStrikerAccessDatabase(['--query', query, '--mode', 'write'], options);

export {
  dbJobAnvilSyncShared,
  dbQuery,
  execDatabaseModuleSubroutine as dbSub,
  dbSubRefreshTimestamp,
  dbWrite,
};
