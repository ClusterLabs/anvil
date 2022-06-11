import { spawnSync } from 'child_process';

import SERVER_PATHS from './consts/SERVER_PATHS';

export const mkfifo = (...args: string[]) => {
  const { error, stderr } = spawnSync(SERVER_PATHS.usr.bin.mkfifo.self, args, {
    encoding: 'utf-8',
    timeout: 3000,
  });

  if (error) {
    throw error;
  }

  if (stderr) {
    throw new Error(stderr);
  }
};
