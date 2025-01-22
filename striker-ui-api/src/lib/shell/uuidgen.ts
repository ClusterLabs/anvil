import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const uuidgen = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.uuidgen.self, args);
