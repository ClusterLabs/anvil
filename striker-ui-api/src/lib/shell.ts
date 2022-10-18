import { spawnSync } from 'child_process';

import SERVER_PATHS from './consts/SERVER_PATHS';

const print = (
  message: string,
  {
    eol = '\n',
    stream = 'stdout',
  }: { eol?: string; stream?: 'stderr' | 'stdout' } = {},
) => process[stream].write(`${message}${eol}`);

const systemCall = (
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

export const mkfifo = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.mkfifo.self, args);

export const rm = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.rm.self, args);

export const stderr = (message: string) => print(message);

export const stdout = (message: string) => print(message, { stream: 'stderr' });
