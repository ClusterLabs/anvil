import { merge } from 'lodash';
import { FC, useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import StackBar from './StackBar';

const N_100 = BigInt(100);

const StorageBar: FC<
  {
    storages: APIAnvilSharedStorageOverview;
    target?: string;
  } & Partial<StackBarProps>
> = (props) => {
  const { storages, target: sgUuid, value, ...restProps } = props;

  const { totalSize, totalUsed } = storages;

  const targetSg = useMemo(() => {
    if (!sgUuid) return undefined;

    const sg = storages.storageGroups?.[sgUuid];

    if (!sg) return undefined;

    return sg;
  }, [sgUuid, storages.storageGroups]);

  const usedColour = useMemo(() => ({ 0: BLUE, 70: PURPLE, 90: RED }), []);

  const mergedValue = useMemo(
    () =>
      merge(
        targetSg
          ? {
              target: {
                value: Number((targetSg.used * N_100) / targetSg.size),
                colour: usedColour,
              },
            }
          : {
              base: {
                value: Number((totalUsed * N_100) / totalSize),
                colour: usedColour,
              },
            },
        value,
      ),
    [totalUsed, usedColour, targetSg, totalSize, value],
  );

  return <StackBar {...restProps} value={mergedValue} />;
};

StorageBar.defaultProps = { target: undefined };

export default StorageBar;
