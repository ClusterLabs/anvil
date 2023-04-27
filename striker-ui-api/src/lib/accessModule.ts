import {
  ChildProcess,
  spawn,
  SpawnOptions,
  spawnSync,
  SpawnSyncOptions,
} from 'child_process';
import EventEmitter from 'events';
import { readFileSync } from 'fs';

import { SERVER_PATHS, PGID, PUID } from './consts';

import { formatSql } from './formatSql';
import {
  date,
  stderr as sherr,
  stdout as shout,
  stdoutVar as shvar,
  uuid,
} from './shell';

type AccessStartOptions = {
  args?: readonly string[];
} & SpawnOptions;

class Access extends EventEmitter {
  private ps: ChildProcess;
  private queue: string[] = [];

  constructor({
    eventEmitterOptions = {},
    spawnOptions = {},
  }: {
    eventEmitterOptions?: ConstructorParameters<typeof EventEmitter>[0];
    spawnOptions?: SpawnOptions;
  } = {}) {
    super(eventEmitterOptions);

    this.ps = this.start(spawnOptions);
  }

  private start({
    args = [],
    gid = PGID,
    stdio = 'pipe',
    timeout = 10000,
    uid = PUID,
    ...restSpawnOptions
  }: AccessStartOptions = {}) {
    shvar({ gid, stdio, timeout, uid, ...restSpawnOptions });

    const ps = spawn(SERVER_PATHS.usr.sbin['anvil-access-module'].self, args, {
      gid,
      stdio,
      timeout,
      uid,
      ...restSpawnOptions,
    });

    let stderr = '';
    let stdout = '';

    ps.stderr?.setEncoding('utf-8').on('data', (chunk: string) => {
      stderr += chunk;

      const scriptId: string | undefined = this.queue[0];

      if (scriptId) {
        sherr(`${Access.event(scriptId, 'stderr')}: ${stderr}`);

        stderr = '';
      }
    });

    ps.stdout?.setEncoding('utf-8').on('data', (chunk: string) => {
      stdout += chunk;

      let nindex: number = stdout.indexOf('\n');

      // 1. ~a is the shorthand for -(a + 1)
      // 2. negatives are evaluated to true
      while (~nindex) {
        const scriptId = this.queue.shift();

        if (scriptId) this.emit(scriptId, stdout.substring(0, nindex));

        stdout = stdout.substring(nindex + 1);
        nindex = stdout.indexOf('\n');
      }
    });

    return ps;
  }

  private stop() {
    this.ps.once('error', () => !this.ps.killed && this.ps.kill('SIGKILL'));

    this.ps.kill();
  }

  private restart(options?: AccessStartOptions) {
    this.ps.once('close', () => this.start(options));

    this.stop();
  }

  private static event(scriptId: string, category: 'stderr'): string {
    return `${scriptId}-${category}`;
  }

  public interact<T>(command: string, ...args: string[]) {
    const { stdin } = this.ps;

    const scriptId = uuid();
    const script = `${command} ${args.join(' ')}\n`;

    const promise = new Promise<T>((resolve, reject) => {
      this.once(scriptId, (data) => {
        let result: T;

        try {
          result = JSON.parse(data);
        } catch (error) {
          return reject(`Failed to parse line ${scriptId}; got [${data}]`);
        }

        return resolve(result);
      });
    });

    shvar({ scriptId, script }, 'Access interact: ');

    this.queue.push(scriptId);
    stdin?.write(script);

    return promise;
  }
}

const access = new Access();

const subroutine = async <T extends unknown[]>(
  subroutine: string,
  {
    params = [],
    pre = ['Database'],
  }: {
    params?: unknown[];
    pre?: string[];
  } = {},
) => {
  const chain = `${pre.join('->')}->${subroutine}`;

  const subParams: string[] = params.map<string>((p) => {
    let result: string;

    try {
      result = JSON.stringify(p);
    } catch (error) {
      result = String(p);
    }

    return `'${result}'`;
  });

  const { sub_results: results } = await access.interact<{ sub_results: T }>(
    'x',
    chain,
    ...subParams,
  );

  shvar(results, `${chain} results: `);

  return results;
};

const query = <T extends (number | null | string)[][]>(script: string) =>
  access.interact<T>('r', formatSql(script));

const write = async (script: string) => {
  const { write_code: wcode } = await access.interact<{ write_code: number }>(
    'w',
    formatSql(script),
  );

  return wcode;
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

const getData = async <T>(...keys: string[]) => {
  const chain = `data->${keys.join('->')}`;

  const {
    sub_results: [data],
  } = await access.interact<{ sub_results: [T] }>('x', chain);

  shvar(data, `${chain} data: `);

  return data;
};

const getFenceSpec = async () => {
  await subroutine('get_fence_data', { pre: ['Striker'] });

  return getData<unknown>('fence_data');
};

const getHostData = async () => {
  await subroutine('get_hosts');

  return getData<AnvilDataHostListHash>('hosts');
};

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

const getLocalHostUuid = () => {
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

const getManifestData = async (manifestUuid?: string) => {
  await subroutine('load_manifest', {
    params: [{ manifest_uuid: manifestUuid }],
    pre: ['Striker'],
  });

  return getData<AnvilDataManifestListHash>('manifests');
};

const getPeerData: GetPeerDataFunction = async (
  target,
  { password, port } = {},
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
  ]: [connected: string, data: PeerDataHash] = await subroutine(
    'get_peer_data',
    {
      params: [{ password, port, target }],
      pre: ['Striker'],
    },
  );

  return {
    hostName,
    hostOS,
    hostUUID,
    isConnected: rawIsConnected === '1',
    isInetConnected: rawIsInetConnected === '1',
    isOSRegistered: rawIsOSRegistered === 'yes',
  };
};

const getUpsSpec = async () => {
  await subroutine('get_ups_data', { pre: ['Striker'] });

  return getData<AnvilDataUPSHash>('ups_data');
};

export {
  dbInsertOrUpdateJob as job,
  dbInsertOrUpdateVariable as variable,
  dbJobAnvilSyncShared,
  dbSubRefreshTimestamp as timestamp,
  getData,
  getFenceSpec,
  getHostData,
  getLocalHostName,
  getLocalHostUuid as getLocalHostUUID,
  getManifestData,
  getPeerData,
  getUpsSpec,
  query,
  subroutine as sub,
  write,
};
