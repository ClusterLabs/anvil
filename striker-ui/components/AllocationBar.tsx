import { makeStyles, withStyles } from '@material-ui/core/styles';
import { LinearProgress } from '@material-ui/core';
import {
  PURPLE_OFF,
  RED_ON,
  BLUE,
  PANEL_BACKGROUND,
} from '../lib/consts/DEFAULT_THEME';

const breakpointWarning = 70;
const breakpointAlert = 90;

const BorderLinearProgress = withStyles({
  root: {
    height: 15,
    borderRadius: 2,
  },
  colorPrimary: {
    backgroundColor: PANEL_BACKGROUND,
  },
  bar: {
    borderRadius: 3,
  },
})(LinearProgress);

const useStyles = makeStyles(() => ({
  barOk: {
    backgroundColor: BLUE,
  },
  barWarning: {
    backgroundColor: PURPLE_OFF,
  },
  barAlert: {
    backgroundColor: RED_ON,
  },
}));

const AllocationBar = ({ allocated }: { allocated: number }): JSX.Element => {
  const classes = useStyles();
  return (
    <>
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
      <LinearProgress variant="determinate" value={0} />
    </>
  );
};

export default AllocationBar;
