const { spawnSync } = require('child_process');

const SERVER_PATHS = require('./consts/SERVER_PATHS');

const execStrikerAccessDatabase = (
  args,
  options = {
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
    throw new Error(stderr);
  }

  let output;

  try {
    output = JSON.parse(stdout);
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

const execDatabaseModuleSubroutine = (subName, subParams, options) => {
  const args = ['--sub', subName];

  if (subParams) {
    args.push('--sub-params', JSON.stringify(subParams));
  }

  const { stdout } = execStrikerAccessDatabase(args, options);

  return {
    stdout: stdout['sub_results'],
  };
};

const accessDB = {
  dbJobAnvilSyncShared: (
    jobName,
    jobData,
    jobTitle,
    jobDescription,
    { jobHostUUID } = { jobHostUUID: 'all' },
  ) => {
    const subParams = {
      file: __filename,
      line: 0,
      job_host_uuid: jobHostUUID,
      job_command: SERVER_PATHS.usr.sbin['anvil-sync-shared'].self,
      job_data: jobData,
      job_name: `storage::${jobName}`,
      job_title: `job_${jobTitle}`,
      job_description: `job_${jobDescription}`,
      job_progress: 0,
    };
    console.log(JSON.stringify(subParams, null, 2));

    return execDatabaseModuleSubroutine('insert_or_update_jobs', subParams)
      .stdout;
  },
  dbQuery: (query, options) =>
    execStrikerAccessDatabase(['--query', query], options),
  dbSub: execDatabaseModuleSubroutine,
  dbSubRefreshTimestamp: () =>
    execDatabaseModuleSubroutine('refresh_timestamp').stdout,
  dbWrite: (query, options) =>
    execStrikerAccessDatabase(['--query', query, '--mode', 'write'], options),
};

module.exports = accessDB;
