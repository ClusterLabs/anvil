import { styled } from '@mui/material';

import { PURPLE, BLUE } from '../../lib/consts/DEFAULT_THEME';

import BorderLinearProgress from './BorderLinearProgress';
import Underline from './Underline';

const PREFIX = 'ProgressBar';

const classes = {
  barOk: `${PREFIX}-barOk`,
  barInProgress: `${PREFIX}-barInProgress`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.barOk}`]: {
    backgroundColor: BLUE,
  },

  [`& .${classes.barInProgress}`]: {
    backgroundColor: PURPLE,
  },
}));

const completed = 100;

const ProgressBar = ({
  progressPercentage,
}: {
  progressPercentage: number;
}): JSX.Element => (
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
    <Underline />
  </StyledDiv>
);

export default ProgressBar;
