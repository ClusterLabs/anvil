import { ChildProcess, spawn } from 'child_process';
import EventEmitter from 'events';
import { readFileSync } from 'fs';

import {
  DEFAULT_JOB_PROGRESS,
  DEBUG_ACCESS,
  PGID,
  PUID,
  REP_UUID,
  SERVER_PATHS,
} from './consts';

import { formatSql } from './formatSql';
import { repeat } from './repeat';
import { date, perr, pout, poutvar, uuid } from './shell';

/**
 * Notes:
 * * This daemon's lifecycle events should follow the naming from systemd.
 */
class Access extends EventEmitter {
  private static readonly VERBOSE: string = repeat('v', DEBUG_ACCESS, {
    prefix: '-',
  });

  private ps: ChildProcess;

  private readonly MAP_TO_EVT_HDL: Record<
    string,
    (args: { options: AccessStartOptions; ps: ChildProcess }) => void
  > = {
    connected: ({ options, ps }) => {
      poutvar(
        options,
        `Successfully started anvil-access-module daemon (pid=${ps.pid}): `,
      );

      this.emit('active', ps.pid);
    },
  };

  constructor({
    eventEmitterOptions = {},
    startOptions = {},
  }: AccessOptions = {}) {
    super(eventEmitterOptions);

    const { args: initial = [], ...rest } = startOptions;

    const args = [...initial, '--emit-events', Access.VERBOSE].filter(
      (value) => value !== '',
    );

    this.ps = this.start({ args, ...rest });
  }

  private start({
    args = [],
    restartInterval = 10000,
    spawnOptions: {
      gid = PGID,
      stdio = 'pipe',
      uid = PUID,
      ...restSpawnOptions
    } = {},
  }: AccessStartOptions = {}) {
    const options = {
      args,
      gid,
      restartInterval,
      stdio,
      uid,
      ...restSpawnOptions,
    };

    poutvar(options, `Starting anvil-access-module daemon with: `);

    const ps = spawn(SERVER_PATHS.usr.sbin['anvil-access-module'].self, args, {
      gid,
      stdio,
      uid,
      ...restSpawnOptions,
    });

    ps.once('error', (error) => {
      perr(
        `anvil-access-module daemon (pid=${ps.pid}) error: ${error.message}`,
        error,
      );
    });

    ps.once('close', (code, signal) => {
      poutvar(
        { code, options, signal },
        `anvil-access-module daemon (pid=${ps.pid}) closed: `,
      );

      this.emit('inactive', ps.pid);

      pout(`Waiting ${restartInterval} before restarting.`);

      setTimeout(() => {
        this.ps = this.start(options);
      }, restartInterval);
    });

    ps.stderr?.setEncoding('utf-8').on('data', (chunk: string) => {
      perr(`anvil-access-module daemon stderr: ${chunk}`);
    });

    let stdout = '';

    ps.stdout?.setEncoding('utf-8').on('data', (chunk: string) => {
      const eventless = chunk.replace(/(\n)?event=([^\n]*)\n/g, (...parts) => {
        poutvar(parts, 'In replacer, args: ');

        const { 1: n = '', 2: event } = parts;

        this.MAP_TO_EVT_HDL[event]?.call(null, { options, ps });

        return n;
      });

      stdout += eventless;

      let nindex: number = stdout.indexOf('\n');

      // 1. ~a is the shorthand for -(a + 1)
      // 2. negative is evaluated to true
      while (~nindex) {
        const scriptId = stdout.substring(0, 36);
        const output = stdout.substring(36, nindex);

        if (REP_UUID.test(scriptId)) {
          this.emit(scriptId, output);
        } else {
          pout(`Access stdout: ${stdout}`);
        }

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
    this.ps.once('close', () => {
      this.ps = this.start(options);
    });

    this.stop();
  }

  public interact<T>(operation: string, ...args: string[]) {
    const { stdin } = this.ps;

    const scriptId = uuid();
    const command = `${operation} ${args.join(' ')}`;
    const script = `${scriptId} ${command}\n`;

    const promise = new Promise<T>((resolve, reject) => {
      this.once(scriptId, (data) => {
        let result: T;

        try {
          result = JSON.parse(data);
        } catch (error) {
          return reject(`Failed to parse line ${scriptId}; got [${data}]`);
        }

        poutvar({ result }, `Access interact ${scriptId} returns: `);

        return resolve(result);
      });
    });

    poutvar({ script }, 'Access interact: ');

    stdin?.write(script);

    return promise;
  }
}

const access = {
  default: new Access(),
  root: new Access({
    startOptions: {
      spawnOptions: { gid: 0, uid: 0 },
    },
  }),
};

const subroutine = async <T extends unknown[]>(
  subroutine: string,
  {
    as = 'default',
    params = [],
    pre = ['Database'],
  }: {
    as?: keyof typeof access;
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

    return `"${result.replaceAll('"', '\\"')}"`;
  });

  const { sub_results: results } = await access[as].interact<{
    sub_results: T;
  }>('x', chain, ...subParams);

  return results;
};

const query = <T extends QueryResult>(script: string) =>
  access.default.interact<T>('r', formatSql(script));

const write = async (script: string) => {
  const { write_code: wcode } = await access.default.interact<{
    write_code: number;
  }>('w', formatSql(script));

  return wcode;
};

const insertOrUpdateJob = async ({
  job_progress = DEFAULT_JOB_PROGRESS,
  line = 0,
  ...rest
}: JobParams) => {
  const [uuid]: [string] = await subroutine('insert_or_update_jobs', {
    params: [{ job_progress, line, ...rest }],
  });

  return uuid;
};

const insertOrUpdateUser: InsertOrUpdateUserFunction = async (params) => {
  const [uuid]: [string] = await subroutine('insert_or_update_users', {
    params: [params],
  });

  return uuid;
};

const insertOrUpdateVariable: InsertOrUpdateVariableFunction = async (
  params,
) => {
  const [uuid]: [string] = await subroutine('insert_or_update_variables', {
    params: [params],
  });

  return uuid;
};

const anvilSyncShared = (
  jobName: string,
  jobData: string,
  jobTitle: string,
  jobDescription: string,
  { jobHostUUID }: JobAnvilSyncSharedOptions = { jobHostUUID: undefined },
) => {
  const subParams: JobParams = {
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

  return insertOrUpdateJob(subParams);
};

const refreshTimestamp = () => {
  let result: string;

  try {
    result = date('--rfc-3339', 'ns').trim();
  } catch (error) {
    throw new Error(
      `Failed to get timestamp for database use; CAUSE: ${error}`,
    );
  }

  return result;
};

const encrypt: EncryptFunction = async (params) => {
  const [result]: [Encrypted] = await subroutine('encrypt_password', {
    params: [params],
    pre: ['Account'],
  });

  return result;
};

const getData = async <T>(...keys: string[]) => {
  const chain = `data->${keys.join('->')}`;

  const {
    sub_results: [data],
  } = await access.default.interact<{ sub_results: [T] }>('x', chain);

  poutvar(data, `${chain} data: `);

  return data;
};

const mutateData = async <T>(args: {
  keys: string[];
  operator: string;
  value: string;
}): Promise<T> => {
  const { keys, operator, value } = args;

  const chain = `data->${keys.join('->')}`;

  const {
    sub_results: [data],
  } = await access.default.interact<{ sub_results: [T] }>(
    'x',
    chain,
    operator,
    value,
  );

  poutvar(data, `${chain} data: `);

  return data;
};

const getAnvilData = async () => {
  await subroutine('get_anvils');

  return getData<AnvilDataAnvilListHash>('anvils');
};

const getDatabaseConfigData = async () => {
  // Empty the existing data->database hash before re-reading updated values.
  await mutateData<string>({ keys: ['database'], operator: '=', value: '{}' });

  const [ecode] = await subroutine<[ecode: string]>('read_config', {
    pre: ['Storage'],
  });

  if (Number(ecode) !== 0) throw new Error(`Failed to read config`);

  return getData<AnvilDataDatabaseHash>('database');
};

const getFenceSpec = async () => {
  await subroutine('get_fence_data', { pre: ['Striker'] });

  return getData<AnvilDataFenceHash>('fence_data');
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

  pout(`localHostName=${result}`);

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

  pout(`localHostUUID=[${result}]`);

  return result;
};

const getManifestData = async (manifestUuid?: string) => {
  await subroutine('load_manifest', {
    params: [{ manifest_uuid: manifestUuid }],
    pre: ['Striker'],
  });

  return getData<AnvilDataManifestListHash>('manifests');
};

const getNetworkData = async (hostUuid: string, hostName?: string) => {
  let replacementKey = hostName;

  if (!replacementKey) {
    ({
      host_uuid: {
        [hostUuid]: { short_host_name: replacementKey },
      },
    } = await getHostData());
  }

  await subroutine('load_interfaces', {
    params: [{ host: replacementKey, host_uuid: hostUuid }],
    pre: ['Network'],
  });

  return getData<AnvilDataNetworkListHash>('network');
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

const getVncinfo = async (serverUuid: string): Promise<ServerDetailVncInfo> => {
  const rows: [[string]] = await query(
    `SELECT variable_value FROM variables WHERE variable_name = 'server::${serverUuid}::vncinfo';`,
  );

  if (!rows.length) {
    throw new Error('No record found');
  }

  const [[vncinfo]] = rows;
  const [domain, rPort] = vncinfo.split(':');

  const port = Number(rPort);
  const protocol = 'ws';

  const result: ServerDetailVncInfo = {
    domain,
    port,
    protocol,
  };

  poutvar(result, `VNC info for server [${serverUuid}]: `);

  return result;
};

const translate = async (value: string): Promise<string> => {
  let result = '';

  try {
    [result] = await subroutine<[string]>('parse_banged_string', {
      params: [{ key_string: value }],
      pre: ['Words'],
    });
  } catch (error) {
    // Log the error and fallback to empty string.
    perr(`Failed to translate; CAUSE: ${error}`);
  }

  return result;
};

export {
  access,
  insertOrUpdateJob as job,
  insertOrUpdateUser,
  insertOrUpdateVariable as variable,
  anvilSyncShared,
  refreshTimestamp as timestamp,
  encrypt,
  getData,
  getAnvilData,
  getDatabaseConfigData,
  getFenceSpec,
  getHostData,
  getLocalHostName,
  getLocalHostUuid as getLocalHostUUID,
  getManifestData,
  getNetworkData,
  getPeerData,
  getUpsSpec,
  getVncinfo,
  mutateData,
  query,
  subroutine as sub,
  translate,
  write,
};
