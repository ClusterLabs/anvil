const partHex = '[0-9a-f]';

export const REP_INTEGER = /^\d+$/;

export const REP_UUID = new RegExp(
  `^${partHex}{8}-${partHex}{4}-[1-5]${partHex}{3}-[89ab]${partHex}{3}-${partHex}{12}$`,
  'i',
);
