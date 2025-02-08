import * as yup from 'yup';

import buildDiskSizeSchema from './buildDiskSizeSchema';
import { yupLaxUuid } from '../../../lib/yupCommons';

const nZero = BigInt(0);

const buildDiskSchema = (
  scope: ProvisionServerScope,
  resources: ProvisionServerResources,
) => {
  const storageGroups = scope.map<ProvisionServerResourceStorageGroup>(
    (group) => resources.storageGroups[group.storageGroup],
  );

  const max = storageGroups.reduce<{ free: bigint }>(
    (previous, sg) => {
      // Find the max free of all storage groups within the scope.
      if (sg.usage.free > previous.free) {
        previous.free = sg.usage.free;
      }

      return previous;
    },
    {
      free: nZero,
    },
  );

  return yup.object({
    size: yup.mixed().when(['storageGroup'], (values) => {
      const [uuid] = values;

      const { [uuid]: sg } = resources.storageGroups;

      if (!sg) {
        return buildDiskSizeSchema(max.free);
      }

      return buildDiskSizeSchema(sg.usage.free);
    }),
    storageGroup: yupLaxUuid(),
  });
};
export default buildDiskSchema;
