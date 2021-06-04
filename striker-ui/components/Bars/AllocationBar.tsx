import { makeStyles, withStyles } from '@material-ui/core/styles';
import { LinearProgress } from '@material-ui/core';
import {
  PURPLE,
  RED,
  BLUE,
  PANEL_BACKGROUND,
  BORDER_RADIUS,
} from '../../lib/consts/DEFAULT_THEME';

const breakpointWarning = 70;
const breakpointAlert = 90;

const BorderLinearProgress = withStyles({
  root: {
    height: '1em',
    borderRadius: BORDER_RADIUS,
  },
  colorPrimary: {
    backgroundColor: PANEL_BACKGROUND,
  },
  bar: {
    borderRadius: BORDER_RADIUS,
  },
})(LinearProgress);

const useStyles = makeStyles(() => ({
  barOk: {
    backgroundColor: BLUE,
  },
  barWarning: {
    backgroundColor: PURPLE,
  },
  barAlert: {
    backgroundColor: RED,
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
