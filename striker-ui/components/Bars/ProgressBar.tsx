import { makeStyles, withStyles } from '@material-ui/core/styles';
import { LinearProgress } from '@material-ui/core';
import {
  PURPLE,
  BLUE,
  PANEL_BACKGROUND,
  BORDER_RADIUS,
} from '../../lib/consts/DEFAULT_THEME';

const completed = 100;

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
  barInProgress: {
    backgroundColor: PURPLE,
  },
}));

const ProgressBar = ({
  progressPercentage,
}: {
  progressPercentage: number;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <>
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
      <LinearProgress variant="determinate" value={0} />
    </>
  );
};

export default ProgressBar;
