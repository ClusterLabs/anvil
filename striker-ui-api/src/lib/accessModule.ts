import { spawn, spawnSync, SpawnSyncOptions } from 'child_process';
import { readFileSync } from 'fs';

import { SERVER_PATHS } from './consts';

import { formatSql } from './formatSql';
import { isObject } from './isObject';
import { date, stderr as sherr, stdout as shout } from './shell';

const asyncAnvilAccessModule = (
  args: string[],
  {
    onClose,
    onError,
    stdio = 'pipe',
    timeout = 60000,
    ...restSpawnOptions
  }: AsyncAnvilAccessModuleOptions = {},
) => {
  const ps = spawn(SERVER_PATHS.usr.sbin['anvil-access-module'].self, args, {
    stdio,
    timeout,
    ...restSpawnOptions,
  });

  let stderr = '';
  let stdout = '';

  ps.once('close', (ecode, signal) => {
    let output;

    try {
      output = JSON.parse(stdout);
    } catch (stdoutParseError) {
      output = stdout;

      sherr(
        `Failed to parse async anvil-access-module stdout; CAUSE: ${stdoutParseError}`,
      );
    }

    onClose?.call(null, { ecode, signal, stderr, stdout: output });
  });

  ps.once('error', (...args) => {
    onError?.call(null, ...args);
  });

  ps.stderr?.setEncoding('utf-8').on('data', (data) => {
    stderr += data;
  });

  ps.stdout?.setEncoding('utf-8').on('data', (data) => {
    stdout += data;
  });
};

const execAnvilAccessModule = (
  args: string[],
  options: SpawnSyncOptions = {},
) => {
  const {
    encoding = 'utf-8',
    timeout = 10000,
    ...restSpawnSyncOptions
  } = options;

  const { error, stderr, stdout } = spawnSync(
    SERVER_PATHS.usr.sbin['anvil-access-module'].self,
    args,
    { encoding, timeout, ...restSpawnSyncOptions },
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

    sherr(
      `Failed to parse anvil-access-module stdout; CAUSE: ${stdoutParseError}`,
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

  shout(
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

const dbInsertOrUpdateJob = (
  { job_progress = 0, line = 0, ...rest }: DBJobParams,
  { spawnSyncOptions }: DBInsertOrUpdateJobOptions = {},
) =>
  execModuleSubroutine('insert_or_update_jobs', {
    spawnSyncOptions,
    subParams: { job_progress, line, ...rest },
  }).stdout;

const dbInsertOrUpdateVariable: DBInsertOrUpdateVariableFunction = (
  subParams,
  { spawnSyncOptions } = {},
) =>
  execModuleSubroutine('insert_or_update_variables', {
    spawnSyncOptions,
    subParams,
  }).stdout;

const dbJobAnvilSyncShared = (
  jobName: string,
  jobData: string,
  jobTitle: string,
  jobDescription: string,
  { jobHostUUID }: DBJobAnvilSyncSharedOptions = { jobHostUUID: undefined },
) => {
  const subParams: DBJobParams = {
    file: __filename,
    job_command: SERVER_PATHS.usr.sbin['anvil-sync-shared'].self,
    job_data: jobData,
    job_name: `storage::${jobName}`,
    job_title: `job_${jobTitle}`,
    job_description: `job_${jobDescription}`,
  };

  if (jobHostUUID) {
    subParams.job_host_uuid = jobHostUUID;
  }

  return dbInsertOrUpdateJob(subParams);
};

const dbQuery = (query: string, options?: SpawnSyncOptions) => {
  shout(formatSql(query));

  return execAnvilAccessModule(['--query', query], options);
};

const dbSubRefreshTimestamp = () => {
  let result: string;

  try {
    result = date('--rfc-3339', 'ns').trim();
  } catch (shError) {
    throw new Error(
      `Failed to get timestamp for database use; CAUSE: ${shError}`,
    );
  }

  return result;
};

const awrite = (
  script: string,
  { onClose: initOnClose, ...restOptions }: AsyncDatabaseWriteOptions = {},
) => {
  shout(formatSql(script));

  const onClose: AsyncAnvilAccessModuleCloseHandler = (args, ...rest) => {
    const { stdout } = args;
    const { obj: output } = isObject(stdout);

    let wcode: number | null = null;

    if ('write_code' in output) {
      ({ write_code: wcode } = output as { write_code: number });

      shout(`Async write completed with write_code=${wcode}`);
    }

    initOnClose?.call(null, { wcode, ...args }, ...rest);
  };

  return asyncAnvilAccessModule(['--query', script, '--mode', 'write'], {
    onClose,
    ...restOptions,
  });
};

const dbWrite = (script: string, options?: SpawnSyncOptions) => {
  shout(formatSql(script));

  return execAnvilAccessModule(['--query', script, '--mode', 'write'], options);
};

const getAnvilData = <HashType>(
  dataStruct: AnvilDataStruct,
  { predata, ...spawnSyncOptions }: GetAnvilDataOptions = {},
): HashType =>
  execAnvilAccessModule(
    [
      '--predata',
      JSON.stringify(predata),
      '--data',
      JSON.stringify(dataStruct),
    ],
    spawnSyncOptions,
  ).stdout;

const getLocalHostName = () => {
  let result: string;

  try {
    result = readFileSync(SERVER_PATHS.etc.hostname.self, {
      encoding: 'utf-8',
    }).trim();
  } catch (subError) {
    throw new Error(`Failed to get local host name; CAUSE: ${subError}`);
  }

  shout(`localHostName=${result}`);

  return result;
};

const getLocalHostUUID = () => {
  let result: string;

  try {
    result = readFileSync(SERVER_PATHS.etc.anvil['host.uuid'].self, {
      encoding: 'utf-8',
    }).trim();
  } catch (subError) {
    throw new Error(`Failed to get local host UUID; CAUSE: ${subError}`);
  }

  shout(`localHostUUID=[${result}]`);

  return result;
};

const getPeerData: GetPeerDataFunction = (
  target,
  { password, port, ...restOptions } = {},
) => {
  const [
    rawIsConnected,
    {
      host_name: hostName,
      host_os: hostOS,
      host_uuid: hostUUID,
      internet: rawIsInetConnected,
      os_registered: rawIsOSRegistered,
    },
  ] = execModuleSubroutine('get_peer_data', {
    subModuleName: 'Striker',
    subParams: { password, port, target },
    ...restOptions,
  }).stdout as [connected: string, data: PeerDataHash];

  return {
    hostName,
    hostOS,
    hostUUID,
    isConnected: rawIsConnected === '1',
    isInetConnected: rawIsInetConnected === '1',
    isOSRegistered: rawIsOSRegistered === 'yes',
  };
};

export {
  awrite,
  dbInsertOrUpdateJob as job,
  dbInsertOrUpdateVariable as variable,
  dbJobAnvilSyncShared,
  dbQuery,
  dbSubRefreshTimestamp as timestamp,
  dbWrite,
  getAnvilData,
  getLocalHostName,
  getLocalHostUUID,
  getPeerData,
  execModuleSubroutine as sub,
};
