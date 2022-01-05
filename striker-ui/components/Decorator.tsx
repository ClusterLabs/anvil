import { styled } from '@mui/material/styles';
import {
  BLUE,
  GREY,
  PURPLE,
  RED,
  BORDER_RADIUS,
} from '../lib/consts/DEFAULT_THEME';

const PREFIX = 'Decorator';

const classes = {
  ok: `${PREFIX}-ok`,
  warning: `${PREFIX}-warning`,
  error: `${PREFIX}-error`,
  off: `${PREFIX}-off`,
};

const StyledDiv = styled('div')(() => ({
  width: '1.4em',
  height: '100%',
  borderRadius: BORDER_RADIUS,

  [`&.${classes.ok}`]: {
    backgroundColor: BLUE,
  },

  [`&.${classes.warning}`]: {
    backgroundColor: PURPLE,
  },

  [`&.${classes.error}`]: {
    backgroundColor: RED,
  },

  [`&.${classes.off}`]: {
    backgroundColor: GREY,
  },
}));

export type Colours = 'ok' | 'off' | 'error' | 'warning';

const Decorator = ({ colour }: { colour: Colours }): JSX.Element => {
  return <StyledDiv className={classes[colour]} />;
};

export default Decorator;
