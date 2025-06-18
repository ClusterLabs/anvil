import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import { PURPLE, BLUE, RED } from '../../lib/consts/DEFAULT_THEME';

import BorderLinearProgress from './BorderLinearProgress';
import Underline from './Underline';

type ProgressBarProps = {
  error?: boolean;
  progressPercentage: number;
};

const PREFIX = 'ProgressBar';

const classes = {
  error: `${PREFIX}-error`,
  ok: `${PREFIX}-ok`,
  inProgress: `${PREFIX}-inProgress`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.error}`]: {
    backgroundColor: RED,
  },

  [`& .${classes.ok}`]: {
    backgroundColor: BLUE,
  },

  [`& .${classes.inProgress}`]: {
    backgroundColor: PURPLE,
  },
}));

const ProgressBar: React.FC<ProgressBarProps> = (props) => {
  const { error, progressPercentage } = props;

  const barClasses = useMemo(() => {
    if (error) {
      return classes.error;
    }

    if (progressPercentage === 100) {
      return classes.ok;
    }

    return classes.inProgress;
  }, [error, progressPercentage]);

  return (
    <StyledDiv>
      <BorderLinearProgress
        classes={{
          bar: barClasses,
        }}
        variant="determinate"
        value={progressPercentage}
      />
      <Underline />
    </StyledDiv>
  );
};

export default ProgressBar;
