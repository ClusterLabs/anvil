import { dSizeStr } from 'format-data-size';

const toBinaryByte = (value: bigint): string | undefined =>
  dSizeStr(value, { toUnit: 'ibyte' });

export default toBinaryByte;
