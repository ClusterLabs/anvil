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

  const mergedValue = useMemo(
    () =>
      merge(
        {
          reserved: {
            value: Number((memory.reserved * N_100) / memory.total),
          },
          allocated: {
            value: Number(
              ((memory.reserved + memory.allocated) * N_100) / memory.total,
            ),
            colour: { 0: BLUE, 70: PURPLE, 90: RED },
          },
        },
        value,
      ),
    [memory.allocated, memory.reserved, memory.total, value],
  );

  return <StackBar {...restProps} value={mergedValue} />;
};

export default MemoryBar;
