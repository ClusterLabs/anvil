import { DEBUG_MAIN } from '../consts';

import { print } from './print';

export const poutvar = DEBUG_MAIN
  ? (variable: unknown, label = 'Variables: ') =>
      print(`${label}${JSON.stringify(variable, null, 2)}`)
  : () => null;
