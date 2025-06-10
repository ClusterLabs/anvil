import {
  Box as MuiBox,
  CircularProgress as MuiCircularProgress,
  CircularProgressProps as MuiCircularProgressProps,
  styled,
} from '@mui/material';
import { useMemo } from 'react';

import { BLUE, DISABLED, PURPLE, RED } from '../lib/consts/DEFAULT_THEME';

const PREFIX = 'PieProgress';

const classes = {
  complete: `${PREFIX}-complete`,
  error: `${PREFIX}-error`,
  inProgress: `${PREFIX}-in-progress`,
};

const BasePieProgress = styled(MuiCircularProgress)({
  [`&.${classes.complete}`]: {
    color: BLUE,
  },

  [`&.${classes.error}`]: {
    color: RED,
  },

  [`&.${classes.inProgress}`]: {
    color: PURPLE,
  },
});

const Underline = styled(MuiCircularProgress)({
  color: DISABLED,
});

const PieProgressBox = styled(MuiBox)({
  position: 'relative',
});

const PieProgress: React.FC<PieProgressProps> = (props) => {
  const { error, slotProps } = props;

  const pieProps = slotProps?.pie;

  const { value: pieValue = pieProps?.value } = props;

  const pieSize = pieProps?.size ?? '1.6em';

  const pieRootClasses = useMemo<string>(() => {
    if (error) {
      return classes.error;
    }

    if (pieValue === 100) {
      return classes.complete;
    }

    return classes.inProgress;
  }, [error, pieValue]);

  const underlineProps = useMemo<MuiCircularProgressProps>(() => {
    const ulProps = slotProps?.underline;

    const thickness = ulProps?.thickness ?? 2;
    const offsetMultiplier = ulProps?.offset?.multiplier ?? 2;

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
