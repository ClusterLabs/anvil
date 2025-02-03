import { ChildProcess, spawn, SpawnOptions } from 'child_process';
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

  private static readonly NAME = 'anvil-access-module daemon';

  private static readonly VERBOSE: string = repeat('v', DEBUG_ACCESS, {
    prefix: '-',
  });

  private active = false;

  private options: Required<AccessOptions>;

  private ps: ChildProcess;

  private socketPath = '';

  constructor({
    emitter: emitterOptions = {},
    start: startOptions = {},
  }: AccessOptions = {}) {
    super(emitterOptions);

    const { args: initialArgs = [], ...restStartOptions } = startOptions;

    // Don't merge in start() to avoid duplicating the args
    const args = [
      ...initialArgs,
      Access.VERBOSE,
      '--daemonize',
      '--working-dir',
      workspace.dir,
    ].filter((value) => value !== '');

    // Init instance's options, but will be updated as defaults are filled in.
    this.options = {
      emitter: emitterOptions,
      start: {
        args,
        ...restStartOptions,
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

        if (beginsUuid.test(line)) {
          const cid = line.substring(0, UUID_LENGTH);
          const out = line.substring(UUID_LENGTH);

          // Commands are executed in order, so just remove the first entry
          // when we get a response.
          cids.shift();

          this.emit(Access.EVT_KEYS.command.out(cid), out);
        } else if (/FATAL/.test(line)) {
          // When the line is a failed password authentication attempt, then
          // try to reconnect to the database because probably
          // anvil-change-password just finished running.
          if (
            ['DBI connect', 'password authentication'].every((phrase) =>
              line.includes(phrase),
            )
          ) {
            this.restart();
          }

          const cid = cids.shift();

          if (cid) {
            const error = new Error(`Failed to finish ${cid}`, {
              cause: line,
            });

            this.emit(Access.EVT_KEYS.command.err(cid), error);
          } else {
            perr(`(${script}) stderr: ${line}`);
          }
        } else {
          pout(`(${script}) stdout: ${line}`);
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
    spawn: { stdio = 'pipe', ...restSpawnOptions } = {},
  }: AccessStartOptions = {}) {
    const spawnOptions: SpawnOptions = {
      stdio,
      ...restSpawnOptions,
    };

    // Update options because they changed due to initialization in start()
    this.options.start = {
      args,
      restartInterval,
      spawn: spawnOptions,
    };

    poutvar(
      {
        options: this.options.start,
      },
      `Starting ${Access.NAME} with: `,
    );

    const ps = spawn(
      SERVER_PATHS.usr.sbin['anvil-access-module'].self,
      args,
      spawnOptions,
    );

    // Don't use .once() because errors can happen multiple times
    ps.on('error', (error) => {
      perr(`${Access.NAME} (pid=${ps.pid}) error: ${error}`);

      if (/FATAL/.test(error.message)) {
        this.ps.kill('SIGTERM');
      }
    });

    ps.once('close', (code, signal) => {
      const startOptions = this.options.start;

      poutvar(
        {
          code,
          options: startOptions,
          signal,
        },
        `${Access.NAME} (pid=${ps.pid}) closed: `,
      );

      this.active = false;

      this.emit('inactive', ps.pid);

      if (!startOptions.restartInterval) {
        return;
      }

      pout(`Waiting ${startOptions.restartInterval} before restarting.`);

      // The local variable 'options' cannot be used in the timeout callback
      // because it will be garbage collected.
      setTimeout(() => {
        this.ps = this.start(this.options.start);
      }, startOptions.restartInterval);
    });

    let stderr = '';

    ps.stderr?.setEncoding('utf-8').on('data', (chunk: string) => {
      stderr += chunk;

      let i: number = stderr.indexOf('\n');

      while (~i) {
        const line = stderr.substring(0, i);

        perr(`${ps.pid}:stderr: ${line}`);

        stderr = stderr.substring(i + 1);

        i = stderr.indexOf('\n');
      }
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
              {
                options: this.options.start,
              },
              `Successfully started ${Access.NAME} (pid=${ps.pid}): `,
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
      return Promise.reject(`${Access.NAME} is not active`);
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
          this.once(Access.EVT_KEYS.command.err(commandId), (error) => {
            reject(`Failed to finish ${commandId}; CAUSE: ${error}`);
          });

          this.once(Access.EVT_KEYS.command.out(commandId), (data) => {
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

  public async restart(
    // Default to shallow copy start options because stop() tampers it.
    options: AccessStartOptions = {
      ...this.options.start,
    },
  ) {
    await this.stop();

    pout(`${Access.NAME} (pid=${this.ps.pid}) stopped, restarting...`);

    this.ps = this.start(options);
  }

  public async stop() {
    this.options.start.restartInterval = 0;

    poutvar(
      {
        options: this.options.start,
      },
      `Stopping ${Access.NAME} (pid=${this.ps.pid}) with: `,
    );

    // Killing can only happen once
    this.ps.once('error', () => {
      if (this.ps.killed) {
        return;
      }

      pout(`Sending SIGKILL...`);

      this.ps.kill('SIGKILL');
    });

    const promise = new Promise<void>((resolve) => {
      this.ps.once('close', () => {
        pout(`${Access.NAME} (pid=${this.ps.pid}) stopped`);

        resolve();
      });
    });

    this.ps.kill('SIGTERM');

    return promise;
  }
}
