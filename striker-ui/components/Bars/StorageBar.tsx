import { merge } from 'lodash';
import { FC, useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import StackBar from './StackBar';

const n100 = BigInt(100);
const nZero = BigInt(0);

const StorageBar: FC<
  {
    storageGroup?: APIAnvilStorageGroupCalcable;
    storages?: APIAnvilSharedStorageOverview;
    target?: string;
    volumeGroup?: APIAnvilVolumeGroupCalcable;
  } & Partial<StackBarProps>
> = (props) => {
  const {
    storageGroup,
    storages,
    target: storageGroupUuid,
    volumeGroup,
    value,
    ...restProps
  } = props;

  const storage = useMemo<{ size: bigint; used: bigint }>(() => {
    let size: bigint = nZero;
    let used: bigint = nZero;

    if (storageGroup) {
      ({ size, used } = storageGroup);

      return { size, used };
    }

    if (volumeGroup) {
      ({ size, used } = volumeGroup);

      return { size, used };
    }

    if (!storages) {
      return { size, used };
    }

    if (storageGroupUuid) {
      const { [storageGroupUuid]: sg } = storages.storageGroups;

      if (sg) {
        ({ size, used } = sg);
      }

      return { size, used };
    }

    ({ totalSize: size, totalUsed: used } = storages);

    return { size, used };
  }, [storageGroup, storageGroupUuid, storages, volumeGroup]);

  const usedColour = useMemo(() => ({ 0: BLUE, 70: PURPLE, 90: RED }), []);

  const mergedValue = useMemo(() => {
    let percentage = 0;

    if (storage.size) {
      percentage = Number((storage.used * n100) / storage.size);
    }

    return merge(
      {
        target: {
          value: percentage,
          colour: usedColour,
        },
      },
      value,
    );
  }, [storage.size, storage.used, usedColour, value]);

  return <StackBar {...restProps} value={mergedValue} />;
};

StorageBar.defaultProps = {
  storageGroup: undefined,
  storages: undefined,
  target: undefined,
  volumeGroup: undefined,
};

export default StorageBar;
