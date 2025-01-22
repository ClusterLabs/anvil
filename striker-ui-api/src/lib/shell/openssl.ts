import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const openssl = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.openssl.self, args);
