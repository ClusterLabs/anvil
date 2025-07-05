import merge from 'lodash/merge';
import { useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import StackBar from './StackBar';

const n100 = BigInt(100);
const nZero = BigInt(0);

type StorageSizes = {
  free: bigint;
  size: bigint;
  used: bigint;
};

type FcStorageBar<S extends StorageSizes> = React.FC<
  {
    storageGroup?: APIAnvilStorageGroupCalcable;
    storages?: APIAnvilSharedStorageOverview;
    target?: string;
    volume?: S;
    volumeGroup?: APIAnvilVolumeGroupCalcable;
  } & Partial<StackBarProps>
>;

const StorageBar = <S extends StorageSizes>(
  ...[props]: Parameters<FcStorageBar<S>>
): ReturnType<FcStorageBar<S>> => {
  const {
    storageGroup,
    storages,
    target: storageGroupUuid,
    volumeGroup,
    value,
    // Depends on previous props
    volume = storageGroup ?? volumeGroup,
    ...restProps
  } = props;

  const storage = useMemo<{
    size: bigint;
    used: bigint;
  }>(() => {
    let size: bigint = nZero;
    let used: bigint = nZero;

    if (volume) {
      ({ size, used } = volume);

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
  }, [storageGroupUuid, storages, volume]);

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
