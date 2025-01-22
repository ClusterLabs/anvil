import { SERVER_PATHS } from '../consts';

import { systemCall } from './systemCall';

export const date = (...args: string[]) =>
  systemCall(SERVER_PATHS.usr.bin.date.self, args);
