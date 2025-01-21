import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const getent = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.getent.self, args);
