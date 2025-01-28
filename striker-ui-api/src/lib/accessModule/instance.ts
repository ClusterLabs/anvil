import { PGID, PUID } from '../consts';

import { Access } from './Access';

export const access = {
  default: new Access({
    startOptions: {
      spawnOptions: {
        gid: PGID,
        uid: PUID,
      },
    },
  }),
  root: new Access({
    startOptions: {
      spawnOptions: {
        gid: 0,
        uid: 0,
      },
    },
  }),
};
