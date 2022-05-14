import { FC } from 'react';

import {
  BORDER_RADIUS,
  MONOSPACE_BACKGROUND,
} from '../../lib/consts/DEFAULT_THEME';

import BodyText, { BodyTextProps } from './BodyText';

const Monospace: FC<BodyTextProps> = ({ sx, ...bodyTextRestProps }) => (
  <BodyText
    {...{
      ...bodyTextRestProps,
      monospaced: true,
      sx: {
        backgroundColor: MONOSPACE_BACKGROUND,
        borderRadius: BORDER_RADIUS,
        display: 'inline',
        padding: '.1rem .3rem',

        ...sx,
      },
    }}
  />
);

export default Monospace;
