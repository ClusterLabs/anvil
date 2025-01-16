import { spawnSync } from 'child_process';

import { DEBUG_MAIN, SERVER_PATHS } from './consts';

const print = (
  message: string,
  {
    eol = '\n',
    stream = 'stdout',
  }: { eol?: string; stream?: 'stderr' | 'stdout' } = {},
) => process[stream].write(`${message}${eol}`);

export const systemCall = (
  ...[command, args = [], options = {}]: Parameters<typeof spawnSync>
) => {
  const { error, stderr, stdout } = spawnSync(command, args, {
    ...options,
    encoding: 'utf-8',
  });

  if (error) {
    throw error;
  }

  if (stderr) {
    throw new Error(stderr);
  }

  return stdout;
};

export const date = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.date.self, args);

export const getent = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.getent.self, args);

export const mkfifo = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.mkfifo.self, args);

export const openssl = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.openssl.self, args);

export const rm = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.rm.self, args);

export const uuidgen = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.uuidgen.self, args);

export const resolveId = (id: number | string, database: string) =>
  Number(getent(database, String(id)).split(':', 3)[2]);

export const resolveGid = (id: number | string) => resolveId(id, 'group');

export const resolveUid = (id: number | string) => resolveId(id, 'passwd');

export const perr = (message: string, error?: unknown) => {
  let msg = message;

  if (error instanceof Error) {
    msg += `\n${error.cause}`;
  }

  print(msg, { stream: 'stderr' });
};

export const pout = DEBUG_MAIN
  ? (message: string) => print(message)
  : () => null;

export const poutvar = DEBUG_MAIN
  ? (variable: unknown, label = 'Variables: ') =>
      print(`${label}${JSON.stringify(variable, null, 2)}`)
  : () => null;

export const uuid = () => uuidgen('--random').trim();
