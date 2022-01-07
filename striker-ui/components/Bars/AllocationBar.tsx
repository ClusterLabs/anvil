import { LinearProgress } from '@mui/material';
import { styled } from '@mui/material/styles';

import {
  PURPLE,
  RED,
  BLUE,
  BORDER_RADIUS,
} from '../../lib/consts/DEFAULT_THEME';
import BorderLinearProgress from './BorderLinearProgress';

const PREFIX = 'AllocationBar';

const classes = {
  barOk: `${PREFIX}-barOk`,
  barWarning: `${PREFIX}-barWarning`,
  barAlert: `${PREFIX}-barAlert`,
  underline: `${PREFIX}-underline`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.barOk}`]: {
    backgroundColor: BLUE,
  },

  [`& .${classes.barWarning}`]: {
    backgroundColor: PURPLE,
  },

  [`& .${classes.barAlert}`]: {
    backgroundColor: RED,
  },

  [`& .${classes.underline}`]: {
    borderRadius: BORDER_RADIUS,
  },
}));

const breakpointWarning = 70;
const breakpointAlert = 90;

const AllocationBar = ({ allocated }: { allocated: number }): JSX.Element => {
  return (
    <StyledDiv>
      <BorderLinearProgress
        classes={{
          bar:
            /* eslint-disable no-nested-ternary */
            allocated > breakpointWarning
              ? allocated > breakpointAlert
                ? classes.barAlert
                : classes.barWarning
              : classes.barOk,
        }}
        variant="determinate"
        value={allocated}
      />
      <LinearProgress
        className={classes.underline}
        variant="determinate"
        value={0}
      />
    </StyledDiv>
  );
};

export default AllocationBar;
