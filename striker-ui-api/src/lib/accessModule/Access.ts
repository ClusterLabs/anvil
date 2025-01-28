import { ChildProcess, spawn } from 'child_process';
import EventEmitter from 'events';
import { createConnection } from 'net';

import { DEBUG_ACCESS, P_UUID, SERVER_PATHS } from '../consts';

import { repeat } from '../repeat';
import { perr, pout, poutvar, uuid } from '../shell';
import { workspace } from '../workspace';

/**
 * Notes:
 * - This daemon's lifecycle events should follow the naming from systemd.
 */
export class Access extends EventEmitter {
  private static readonly VERBOSE: string = repeat('v', DEBUG_ACCESS, {
    prefix: '-',
  });

  private ps: ChildProcess;

  private socketPath = '';

  private readonly EVT_KEYS = {
    command: {
      err: (id: string) => `${id}-err`,
      out: (id: string) => `${id}-out`,
    },
  };

  constructor({
    eventEmitterOptions = {},
    startOptions = {},
  }: AccessOptions = {}) {
    super(eventEmitterOptions);

    const { args: initial = [], ...rest } = startOptions;

    const args = [
      ...initial,
      Access.VERBOSE,
      '--daemonize',
      '--working-dir',
      workspace.dir,
    ].filter((value) => value !== '');

    this.ps = this.start({ args, ...rest });
  }

  private send(script: string) {
    const requester = createConnection(
      {
        path: this.socketPath,
      },
      () => {
        poutvar({ script }, `Requester connected: `);

        requester.write(script);
        requester.end();
      },
    );

    requester.setEncoding('utf-8');

    let stdout = '';

    requester.on('data', (data) => {
      stdout += data.toString();

      let i: number = stdout.indexOf('\n');

      const beginsUuid = new RegExp(`^${P_UUID}`);

      // 1. ~a is the shorthand for -(a + 1)
      // 2. negative is evaluated to true
      while (~i) {
        const line = stdout.substring(0, i);

        if (/^event=/.test(line)) {
          const event = line.substring(6);

          if (/exit$/.test(event)) {
            requester.end();
          }
        } else if (beginsUuid.test(line)) {
          const id = line.substring(0, 36);
          const out = line.substring(36);

          this.emit(this.EVT_KEYS.command.out(id), out);
        } else {
          poutvar({ line }, `Access output: `);
        }

        stdout = stdout.substring(i + 1);

        i = stdout.indexOf('\n');
      }
    });

    requester.on('error', (error) => {
      perr(`Requester (${script}) error: ${error.message}`);
    });

    requester.on('end', () => {
      poutvar({ script }, `Requester disconnected: `);
    });
  }

  private start({
    args = [],
    restartInterval = 10000,
    spawnOptions: { gid, stdio = 'pipe', uid, ...restSpawnOptions } = {},
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

    // Make sure only the parent writes to the stdout
    let stdout = '';

    ps.stdout?.setEncoding('utf-8').on('data', (chunk: string) => {
      stdout += chunk;

      let i: number = stdout.indexOf('\n');

      // 1. ~a is the shorthand for -(a + 1)
      // 2. negative is evaluated to true
      while (~i) {
        const line = stdout.substring(0, i);

        if (/^event=/.test(line)) {
          const event = line.substring(6);

          if (/^socket:/.test(event)) {
            this.socketPath = event.substring(7);

            pout(`Got socket path: ${this.socketPath}`);
          } else if (event === 'listening') {
            poutvar(
              options,
              `Successfully started anvil-access-module daemon (pid=${ps.pid}): `,
            );

            this.emit('active', ps.pid);
          }
        }

        stdout = stdout.substring(i + 1);

        i = stdout.indexOf('\n');
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
    const mapToCommands = ops.reduce<Record<string, string>>((previous, op) => {
      const commandId = uuid();

      previous[commandId] = `${commandId} ${op}`;

      return previous;
    }, {});

    const script = `${Object.values(mapToCommands).join(' ;; ')}\n`;

    poutvar({ script }, 'Access interact: ');

    this.send(script);

    const promises = Object.keys(mapToCommands).map<Promise<E>>((commandId) => {
      const promise = new Promise<E>((resolve, reject) => {
        this.on(this.EVT_KEYS.command.out(commandId), (data) => {
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

      return promise;
    });

    return Promise.all(promises) as Promise<A>;
  }
}
