import { makeStyles } from '@material-ui/core/styles';
import { BLUE, GREY, PURPLE, RED } from '../lib/consts/DEFAULT_THEME';

export type Colours = 'ok' | 'off' | 'error' | 'warning';

const useStyles = makeStyles(() => ({
  decorator: {
    width: '1.4em',
    height: '100%',
    borderRadius: 2,
  },
  ok: {
    backgroundColor: BLUE,
  },
  warning: {
    backgroundColor: PURPLE,
  },
  error: {
    backgroundColor: RED,
  },
  off: {
    backgroundColor: GREY,
  },
}));

const Decorator = ({ colour }: { colour: Colours }): JSX.Element => {
  const classes = useStyles();
  return <div className={`${classes.decorator} ${classes[colour]}`} />;
};

export default Decorator;
