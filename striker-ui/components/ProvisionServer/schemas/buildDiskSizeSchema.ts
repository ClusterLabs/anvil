import { yupDataSize } from '../../../lib/yupCommons';

// Unit: bytes; 100 MiB
const min = BigInt(104857600);

const buildDiskSizeSchema = (max: bigint) => yupDataSize({ max, min });

export default buildDiskSizeSchema;
