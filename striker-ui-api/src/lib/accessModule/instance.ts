import { Access } from './Access';

export const access = {
  default: new Access(),
  root: new Access({
    startOptions: {
      spawnOptions: { gid: 0, uid: 0 },
    },
  }),
};
