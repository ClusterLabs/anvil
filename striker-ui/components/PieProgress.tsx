import { CircularProgress, CircularProgressProps, styled } from '@mui/material';
import { FC, useMemo } from 'react';

import { BLUE, PURPLE } from '../lib/consts/DEFAULT_THEME';

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

const PieProgress: FC<CircularProgressProps> = (props) => {
  const { value, ...restProps } = props;

  const rootClasses = useMemo<string>(
    () => (value && value === 100 ? classes.complete : classes.inProgress),
    [value],
  );

  return (
    <BasePieProgress
      classes={{ root: rootClasses }}
      size="1.6em"
      thickness={22}
      value={value}
      variant="determinate"
      {...restProps}
    />
  );
};

export default PieProgress;
