import { LinearProgress } from '@mui/material';
import { styled } from '@mui/material/styles';

import { PURPLE, BLUE, BORDER_RADIUS } from '../../lib/consts/DEFAULT_THEME';
import BorderLinearProgress from './BorderLinearProgress';

const PREFIX = 'ProgressBar';

const classes = {
  barOk: `${PREFIX}-barOk`,
  barInProgress: `${PREFIX}-barInProgress`,
  underline: `${PREFIX}-underline`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.barOk}`]: {
    backgroundColor: BLUE,
  },

  [`& .${classes.barInProgress}`]: {
    backgroundColor: PURPLE,
  },

  [`& .${classes.underline}`]: {
    borderRadius: BORDER_RADIUS,
  },
}));

const completed = 100;

const ProgressBar = ({
  progressPercentage,
}: {
  progressPercentage: number;
}): JSX.Element => {
  return (
    <StyledDiv>
      <BorderLinearProgress
        classes={{
          bar:
            progressPercentage < completed
              ? classes.barInProgress
              : classes.barOk,
        }}
        variant="determinate"
        value={progressPercentage}
      />
      <LinearProgress
        className={classes.underline}
        variant="determinate"
        value={0}
      />
    </StyledDiv>
  );
};

export default ProgressBar;
