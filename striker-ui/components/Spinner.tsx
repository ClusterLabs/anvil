import { makeStyles } from '@material-ui/core/styles';
import CircularProgress from '@material-ui/core/CircularProgress';

const useStyles = makeStyles(() => ({
  root: {
    display: 'flex',
    /* '& > * + *': {
      marginLeft: theme.spacing(2),
    }, */
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: '3em',
  },
  spinner: {
    color: '#FFF',
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
