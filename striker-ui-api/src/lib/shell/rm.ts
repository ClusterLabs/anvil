import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const rm = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.rm.self, args);
