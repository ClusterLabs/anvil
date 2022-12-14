import { Box as MUIBox, BoxProps as MUIBoxProps } from '@mui/material';
import { FC } from 'react';
import {
  BLUE,
  GREY,
  PURPLE,
  RED,
  BORDER_RADIUS,
} from '../lib/consts/DEFAULT_THEME';

export type Colours = 'ok' | 'off' | 'error' | 'warning';

type DecoratorProps = MUIBoxProps & {
  colour: Colours;
};

const PREFIX = 'Decorator';

const classes = {
  ok: `${PREFIX}-ok`,
  warning: `${PREFIX}-warning`,
  error: `${PREFIX}-error`,
  off: `${PREFIX}-off`,
};

const Decorator: FC<DecoratorProps> = ({
  colour,
  sx,
  ...restDecoratorProps
}): JSX.Element => (
  <MUIBox
    {...{
      ...restDecoratorProps,
      className: classes[colour],
      sx: {
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

        ...sx,
      },
    }}
  />
);

export default Decorator;
