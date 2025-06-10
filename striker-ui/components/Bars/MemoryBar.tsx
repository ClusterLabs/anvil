import { merge } from 'lodash';
import { useMemo } from 'react';

import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';

import StackBar from './StackBar';

const n100 = BigInt(100);

const MemoryBar: React.FC<
  {
    memory: AnvilMemoryCalcable;
  } & Partial<StackBarProps>
> = (props) => {
  const { memory, value, ...restProps } = props;

  const { allocated, reserved, total } = memory;

  const allocatedColour = useMemo(() => {
    const usable: bigint = total - reserved;

    const max = Number((usable * n100) / total);

    const colour = {
      0: BLUE,
      [String(max * 0.7)]: PURPLE,
      [String(max * 0.9)]: RED,
    };

    return colour;
  }, [reserved, total]);

  const mergedValue = useMemo(() => {
    let percentAllocated = 0;
    let percentReserved = 0;

    if (total) {
      percentAllocated = Number((allocated * n100) / total);
      percentReserved = Number((reserved * n100) / total);
    }

    return merge(
      {
        reserved: {
          barProps: { sx: { rotate: '180deg' } },
          value: percentReserved,
        },
        allocated: {
          value: percentAllocated,
          colour: allocatedColour,
        },
      },
      value,
    );
  }, [allocated, allocatedColour, reserved, total, value]);

  return <StackBar {...restProps} value={mergedValue} />;
};

export default MemoryBar;
