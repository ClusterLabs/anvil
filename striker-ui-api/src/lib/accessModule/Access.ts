import { ChildProcess, spawn } from 'child_process';
import EventEmitter from 'events';
import { createConnection } from 'net';

import { DEBUG_ACCESS, P_UUID, SERVER_PATHS, UUID_LENGTH } from '../consts';

import { repeat } from '../repeat';
import { perr, pout, poutvar, uuid } from '../shell';
import { workspace } from '../workspace';

/**
 * Notes:
 * - This daemon's lifecycle events should follow the naming from systemd.
 */
export class Access extends EventEmitter {
  private static readonly EVT_KEYS = {
    command: {
      err: (id: string) => `${id}-err`,
      out: (id: string) => `${id}-out`,
    },
  };

  private static readonly VERBOSE: string = repeat('v', DEBUG_ACCESS, {
    prefix: '-',
  });

  private active = false;

  private options: AccessOptions;

  private ps: ChildProcess;

  private socketPath = '';

  constructor(options: AccessOptions = {}) {
    const { emitter: emitterOptions, start: startOptions = {} } = options;

    super(emitterOptions);

    const { args: initial = [], ...rest } = startOptions;

    const args = [
      ...initial,
      Access.VERBOSE,
      '--daemonize',
      '--working-dir',
      workspace.dir,
    ].filter((value) => value !== '');

    this.options = {
      emitter: emitterOptions,
      start: {
        args,
        ...rest,
      },
    };

    this.ps = this.start(this.options.start);
  }

  private send(script: string, commandIds: string[]) {
    // Make a copy to avoid changing the original.
    const cids = [...commandIds];

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
          const cid = line.substring(0, UUID_LENGTH);
          const out = line.substring(UUID_LENGTH);

          // Commands are executed in order, so just remove the first entry
          // when we get a response.
          cids.shift();

          this.emit(Access.EVT_KEYS.command.out(cid), out);
        } else {
          poutvar({ line }, `Access output: `);
        }

        stdout = stdout.substring(i + 1);

        i = stdout.indexOf('\n');
      }
    });

    requester.on('error', (error) => {
      const cid = cids.shift();

      perr(`Requester (${cid} **of** ${script}) error: ${error}`);

      if (!cid) {
        return;
      }

      this.emit(Access.EVT_KEYS.command.err(cid), error);
    });

    requester.on('end', () => {
      poutvar({ script }, `Requester disconnected: `);

      // Clean up all listeners for each command in the script
      commandIds.forEach((cid) => {
        this.removeAllListeners(Access.EVT_KEYS.command.err(cid));
        this.removeAllListeners(Access.EVT_KEYS.command.out(cid));
      });
    });
  }

  private start({
    args = [],
    restartInterval = 10000,
    spawn: { gid, stdio = 'pipe', uid, ...restSpawnOptions } = {},
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
      perr(`anvil-access-module daemon (pid=${ps.pid}) error: ${error}`);

      if (/fatal/i.test(error.message)) {
        this.ps.kill('SIGTERM');
      }
    });

    ps.once('close', (code, signal) => {
      poutvar(
        { code, options, signal },
        `anvil-access-module daemon (pid=${ps.pid}) closed: `,
      );

      this.active = false;

      this.emit('inactive', ps.pid);

      pout(`Waiting ${restartInterval} before restarting.`);

      // The local variable 'options' cannot be used in the timeout callback
      // because it will be garbage collected.
      setTimeout(() => {
        this.ps = this.start(this.options.start);
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

            this.active = true;

            this.emit('active', ps.pid);
          }
        }

        stdout = stdout.substring(i + 1);

        i = stdout.indexOf('\n');
      }
    });

    return ps;
  }

  public interact<A extends unknown[], E extends A[number] = A[number]>(
    ...ops: string[]
  ) {
    if (!this.active) {
      return Promise.reject(`anvil-access-module daemon is not active`);
    }

    const mapToCommands = ops.reduce<Record<string, string>>((previous, op) => {
      const commandId = uuid();

      previous[commandId] = `${commandId} ${op}`;

      return previous;
    }, {});

    const script = `${Object.values(mapToCommands).join(' ;; ')}\n`;

    poutvar({ script }, 'Access interact: ');

    const commandIds = Object.keys(mapToCommands);

    this.send(script, commandIds);

    const promises = commandIds.map<Promise<E>>(
      (commandId) =>
        new Promise<E>((resolve, reject) => {
          this.on(Access.EVT_KEYS.command.err(commandId), (error) => {
            reject(`Failed to finish ${commandId}; CAUSE: ${error}`);
          });

          this.on(Access.EVT_KEYS.command.out(commandId), (data) => {
            let result: E;

            try {
              result = JSON.parse(data);
            } catch (error) {
              return reject(`Failed to parse line ${commandId}; got [${data}]`);
            }

            poutvar({ result }, `Access interact ${commandId} returns: `);

            return resolve(result);
          });
        }),
    );

    return Promise.all(promises) as Promise<A>;
  }

  public async restart(options?: AccessStartOptions) {
    await this.stop();

    this.ps = this.start(options);
  }

  public async stop() {
    // Remove other listeners that might interfere with the clean up
    this.ps.removeAllListeners();

    const promise = new Promise<void>((resolve) => {
      this.ps.once('close', (code, signal) => {
        poutvar(
          { code, options: this.options.start, signal },
          `Stopped anvil-access-module daemon (pid=${this.ps.pid}); params: `,
        );

        this.active = false;

        this.emit('inactive', this.ps.pid);

        resolve();
      });

      this.ps.once('error', (error) => {
        perr(
          `Failed to stop anvil-access-module daemon (pid=${this.ps.pid}); CAUSE: ${error}`,
        );

        if (this.ps.killed) {
          return;
        }

        this.ps.kill('SIGKILL');
      });
    });

    this.ps.kill('SIGTERM');

    return promise;
  }
}
