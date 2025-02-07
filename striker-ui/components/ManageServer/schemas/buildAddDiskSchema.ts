import * as yup from 'yup';

import { buildDiskSizeSchema } from '../../ProvisionServer';
import { yupLaxUuid } from '../../../lib/yupCommons';

const buildAddDiskSchema = (sgs: APIAnvilSharedStorageOverview | undefined) =>
  yup.object({
    size: yup.mixed().when(['storage'], (values, schema) => {
      const [sgUuid] = values;

      const sg = sgs?.storageGroups[sgUuid];

      if (!sg) {
        return schema;
      }

      return buildDiskSizeSchema(sg.free);
    }),
    storage: yupLaxUuid(),
  });

export default buildAddDiskSchema;
