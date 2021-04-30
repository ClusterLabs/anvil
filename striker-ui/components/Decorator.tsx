import { makeStyles } from '@material-ui/core/styles';
import { BLUE, GREY, PURPLE_OFF, RED_ON } from '../lib/consts/DEFAULT_THEME';

export type Colours = 'ok' | 'off' | 'error' | 'warning';

const useStyles = makeStyles(() => ({
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  ok: {
    backgroundColor: BLUE,
  },
  warning: {
    backgroundColor: PURPLE_OFF,
  },
  error: {
    backgroundColor: RED_ON,
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
