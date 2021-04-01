import { makeStyles, withStyles } from '@material-ui/core/styles';
import { LinearProgress } from '@material-ui/core';
import {
  PURPLE_OFF,
  BLUE,
  PANEL_BACKGROUND,
} from '../lib/consts/DEFAULT_THEME';

const completed = 100;

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
  barInProgress: {
    backgroundColor: PURPLE_OFF,
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
