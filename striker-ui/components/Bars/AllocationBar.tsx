import { styled } from '@mui/material';

import { PURPLE, RED, BLUE } from '../../lib/consts/DEFAULT_THEME';

import BorderLinearProgress from './BorderLinearProgress';
import Underline from './Underline';



const PREFIX = 'AllocationBar';

const classes = {
  barOk: `${PREFIX}-barOk`,
  barWarning: `${PREFIX}-barWarning`,
  barAlert: `${PREFIX}-barAlert`,
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
}));

const breakpointWarning = 70;
const breakpointAlert = 90;

const AllocationBar = ({ allocated }: { allocated: number }): React.ReactElement => (
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
    <Underline />
  </StyledDiv>
);

export default AllocationBar;
