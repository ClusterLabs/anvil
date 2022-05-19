import { FC } from 'react';

import BodyText, { BodyTextProps } from './BodyText';

const Monospace: FC<BodyTextProps> = ({ sx, ...bodyTextRestProps }) => (
  <BodyText
    {...{
      ...bodyTextRestProps,
      monospaced: true,
      sx: {
        display: 'inline',
        padding: '.1rem .3rem',

        ...sx,
      },
    }}
  />
);

export default Monospace;
