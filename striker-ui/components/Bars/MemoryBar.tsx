import { merge } from 'lodash';
import { FC, useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import StackBar from './StackBar';

const N_100 = BigInt(100);

const MemoryBar: FC<
  {
    memory: AnvilMemoryCalcable;
  } & Partial<StackBarProps>
> = (props) => {
  const { memory, value, ...restProps } = props;

  const { allocated, reserved, total } = memory;

  const allocatedColour = useMemo(() => {
    const usable: bigint = total - reserved;

    const max = Number((usable * N_100) / total);

    const colour = {
      0: BLUE,
      [String(max * 0.7)]: PURPLE,
      [String(max * 0.9)]: RED,
    };

    return colour;
  }, [reserved, total]);

  const mergedValue = useMemo(
    () =>
      merge(
        {
          reserved: {
            barProps: { sx: { rotate: '180deg' } },
            value: Number((reserved * N_100) / total),
          },
          allocated: {
            value: Number((allocated * N_100) / total),
            colour: allocatedColour,
          },
        },
        value,
      ),
    [allocated, allocatedColour, reserved, total, value],
  );

  return <StackBar {...restProps} value={mergedValue} />;
};

export default MemoryBar;
