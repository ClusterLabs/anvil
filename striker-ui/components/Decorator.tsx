import { Box, BoxProps, styled } from '@mui/material';
import { FC } from 'react';

import {
  BLUE,
  GREY,
  PURPLE,
  RED,
  BORDER_RADIUS,
} from '../lib/consts/DEFAULT_THEME';

type Colours = 'ok' | 'off' | 'error' | 'warning';

type DecoratorProps = BoxProps & {
  colour: Colours;
};

const PREFIX = 'Decorator';

const classes = {
  ok: `${PREFIX}-ok`,
  warning: `${PREFIX}-warning`,
  error: `${PREFIX}-error`,
  off: `${PREFIX}-off`,
};

const BaseBox = styled(Box)({
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

const Decorator: FC<DecoratorProps> = ({ colour, ...restDecoratorProps }) => (
  <BaseBox {...restDecoratorProps} className={classes[colour]} />
);

export type { Colours };

export default Decorator;
