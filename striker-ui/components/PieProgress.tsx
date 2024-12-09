import {
  Box,
  CircularProgress,
  CircularProgressProps,
  styled,
} from '@mui/material';
import { useMemo } from 'react';

import { BLUE, DISABLED, PURPLE } from '../lib/consts/DEFAULT_THEME';

const PREFIX = 'PieProgress';

const classes = {
  complete: `${PREFIX}-complete`,
  inProgress: `${PREFIX}-in-progress`,
};

const BasePieProgress = styled(CircularProgress)({
  [`&.${classes.complete}`]: {
    color: BLUE,
  },

  [`&.${classes.inProgress}`]: {
    color: PURPLE,
  },
});

const Underline = styled(CircularProgress)({
  color: DISABLED,
});

const PieProgressBox = styled(Box)({
  position: 'relative',
});

const PieProgress: React.FC<PieProgressProps> = (props) => {
  const { slotProps } = props;

  const pieProps = slotProps?.pie;

  const { value: pieValue = pieProps?.value } = props;

  const pieSize = pieProps?.size ?? '1.6em';

  const pieRootClasses = useMemo<string>(
    () =>
      pieValue && pieValue === 100 ? classes.complete : classes.inProgress,
    [pieValue],
  );

  const underlineProps = useMemo<CircularProgressProps>(() => {
    const ulProps = slotProps?.underline;

    const thickness = ulProps?.thickness ?? 6;
    const offsetMultiplier = ulProps?.offset?.multiplier ?? 1;

    const offset = thickness * offsetMultiplier;
    const offsetUnit = ulProps?.offset?.unit ?? 'px';
    const halfOffset = offset * 0.5;

    const size = `calc(${pieSize} + ${offset}${offsetUnit})`;

    return {
      size,
      sx: {
        position: 'absolute',
        top: `-${halfOffset}${offsetUnit}`,
        left: `-${halfOffset}${offsetUnit}`,
      },
      thickness,
      value: 100,
      variant: 'determinate',
      ...slotProps?.underline,
    };
  }, [pieSize, slotProps?.underline]);

  return (
    <PieProgressBox {...slotProps?.box}>
      <Underline {...underlineProps} />
      <BasePieProgress
        classes={{ root: pieRootClasses }}
        size={pieSize}
        thickness={22}
        value={pieValue}
        variant="determinate"
        {...pieProps}
      />
    </PieProgressBox>
  );
};

export default PieProgress;
