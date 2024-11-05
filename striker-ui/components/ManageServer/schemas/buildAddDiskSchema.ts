import * as yup from 'yup';

import { yupDataSize, yupLaxUuid } from '../../../lib/yupCommons';

// Unit: bytes; 100 MiB
const nMin = BigInt(104857600);

const buildAddDiskSchema = (sgs: APIAnvilSharedStorageOverview | undefined) =>
  yup.object({
    size: yup.mixed().when(['storage'], (values, schema) => {
      const [sgUuid] = values;

      const sg = sgs?.storageGroups[sgUuid];

      if (!sg) return schema;

      return yupDataSize({ max: sg.free, min: nMin });
    }),
    storage: yupLaxUuid(),
  });

export default buildAddDiskSchema;
