import * as yup from 'yup';

import { yupDataSize } from '../../../lib/yupCommons';

// Unit: bytes; 64 KiB
const nMin = BigInt(65536);

/* eslint-disable no-template-curly-in-string */

const buildMemorySchema = (memory: AnvilMemoryCalcable) => {
  const { available: nMax } = memory;

  return yup.object({
    size: yupDataSize({ max: nMax, min: nMin }),
  });
};

export default buildMemorySchema;
