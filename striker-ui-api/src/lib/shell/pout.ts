import { DEBUG_MAIN } from '../consts';

import { print } from './print';

export const pout = DEBUG_MAIN
  ? (message: string) => print(message)
  : () => null;
