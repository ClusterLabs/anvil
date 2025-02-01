import { chownSync, existsSync, mkdirSync, rmSync } from 'fs';

import { workingDir } from './dir';

export const mkdir = (uid: number, gid?: number): void => {
  const exists = existsSync(workingDir);

  if (exists) {
    rmSync(workingDir, {
      force: true,
      recursive: true,
    });
  }

  mkdirSync(workingDir, {
    recursive: true,
  });

  const groupId = gid ?? uid;

  chownSync(workingDir, uid, groupId);
};
