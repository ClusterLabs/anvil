import { makeStyles, withStyles } from '@material-ui/core/styles';
import { LinearProgress, Typography } from '@material-ui/core';
import {
  PURPLE_OFF,
  PANEL_BACKGROUND,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';

const BorderLinearProgress = withStyles({
  root: {
    height: 25,
    borderRadius: 3,
  },
  colorPrimary: {
    backgroundColor: PANEL_BACKGROUND,
  },
  bar: {
    borderRadius: 3,
    backgroundColor: PURPLE_OFF,
  },
})(LinearProgress);

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
  },
  margin: {
    margin: theme.spacing(1),
  },
  leftLabel: {
    position: 'absolute',
    color: TEXT,
    top: 0,
    left: '5%',
  },
  centerLabel: {
    position: 'absolute',
    color: TEXT,
    top: 0,
    left: '70%',
  },
  rightLabel: {
    position: 'absolute',
    color: TEXT,
    top: 0,
    left: '90%',
  },
}));

const ProgressBar = ({ allocated }: { allocated: number }): JSX.Element => {
  const classes = useStyles();

  return (
    <div style={{ position: 'relative' }}>
      <BorderLinearProgress variant="determinate" value={allocated} />
      <Typography className={classes.leftLabel}>53.5%</Typography>
      <Typography className={classes.centerLabel}>570MiB/s</Typography>
      <Typography className={classes.rightLabel}>1:15:30</Typography>
      <LinearProgress variant="determinate" value={0} />
    </div>
  );
};

export default ProgressBar;
