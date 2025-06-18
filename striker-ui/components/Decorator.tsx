import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

import {
  BLUE,
  GREY,
  PURPLE,
  RED,
  BORDER_RADIUS,
} from '../lib/consts/DEFAULT_THEME';

type Colours = 'ok' | 'off' | 'error' | 'warning';

type DecoratorProps = MuiBoxProps & {
  colour: Colours;
};

const PREFIX = 'Decorator';

const classes = {
  ok: `${PREFIX}-ok`,
  warning: `${PREFIX}-warning`,
  error: `${PREFIX}-error`,
  off: `${PREFIX}-off`,
};

const BaseBox = styled(MuiBox)({
  borderRadius: BORDER_RADIUS,
  height: '100%',
  width: '1.4em',

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
});

const Decorator: React.FC<DecoratorProps> = ({
  colour,
  ...restDecoratorProps
}) => <BaseBox {...restDecoratorProps} className={classes[colour]} />;

export type { Colours };

export default Decorator;
