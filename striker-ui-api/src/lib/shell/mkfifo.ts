import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const mkfifo = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.mkfifo.self, args);
