import { PGID, PUID } from '../consts';

import { Access } from './Access';

export const access = {
  default: new Access({
    start: {
      spawn: {
        gid: PGID,
        uid: PUID,
      },
    },
  }),
};
