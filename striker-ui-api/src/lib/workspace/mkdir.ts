import { chownSync, existsSync, mkdirSync } from 'fs';

import { workingDir } from './dir';

export const mkdir = (uid: number, gid?: number): void => {
  const exists = existsSync(workingDir);

  if (exists) {
    return;
  }

  mkdirSync(workingDir, {
    recursive: true,
  });

  const groupId = gid ?? uid;

  chownSync(workingDir, uid, groupId);
};
