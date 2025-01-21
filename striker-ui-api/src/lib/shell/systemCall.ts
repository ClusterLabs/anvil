import { spawnSync } from 'child_process';

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
