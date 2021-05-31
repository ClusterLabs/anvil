import { makeStyles } from '@material-ui/core/styles';
import CircularProgress from '@material-ui/core/CircularProgress';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  root: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: '3em',
  },
  spinner: {
    color: TEXT,
    variant: 'indeterminate',
    size: '50em',
  },
}));

const Spinner = (): JSX.Element => {
  const classes = useStyles();

  return (
    <div className={classes.root}>
      <CircularProgress className={classes.spinner} />
    </div>
  );
};

export default Spinner;
