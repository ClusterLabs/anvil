import { ChildProcess, spawn } from 'child_process';
import EventEmitter from 'events';

import { DEBUG_ACCESS, PGID, PUID, REP_UUID, SERVER_PATHS } from '../consts';

import { repeat } from '../repeat';
import { perr, pout, poutvar, uuid } from '../shell';

/**
 * Notes:
 * - This daemon's lifecycle events should follow the naming from systemd.
 */
export class Access extends EventEmitter {
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

    const args = [...initial, Access.VERBOSE].filter((value) => value !== '');

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
        const commandId = stdout.substring(0, 36);
        const output = stdout.substring(36, nindex);

        if (REP_UUID.test(commandId)) {
          this.emit(commandId, output);
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

  public interact<A extends unknown[], E extends A[number] = A[number]>(
    ...ops: string[]
  ) {
    const { stdin } = this.ps;

    const promises: Promise<E>[] = [];

    const commands = ops.map<string>((op) => {
      const commandId = uuid();
      const command = `${commandId} ${op}`;

      const promise = new Promise<E>((resolve, reject) => {
        this.once(commandId, (data) => {
          let result: E;

          try {
            result = JSON.parse(data);
          } catch (error) {
            return reject(`Failed to parse line ${commandId}; got [${data}]`);
          }

          poutvar({ result }, `Access interact ${commandId} returns: `);

          return resolve(result);
        });
      });

      promises.push(promise);

      return command;
    });

    const script = `${commands.join(' ;; ')}\n`;

    poutvar({ script }, 'Access interact: ');

    stdin?.write(script);

    return Promise.all(promises) as Promise<A>;
  }
}
