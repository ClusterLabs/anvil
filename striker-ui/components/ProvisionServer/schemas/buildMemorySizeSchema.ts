import { yupDataSize } from '../../../lib/yupCommons';

// Unit: bytes; 64 KiB
const min = BigInt(65536);

const buildMemorySizeSchema = (max: bigint) => yupDataSize({ max, min });

export default buildMemorySizeSchema;
