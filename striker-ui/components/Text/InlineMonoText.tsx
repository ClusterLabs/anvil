import { FC } from 'react';

import { BodyTextProps } from './BodyText';
import SmallText from './SmallText';

const InlineMonoText: FC<BodyTextProps> = ({ sx, ...bodyTextRestProps }) => (
  <SmallText
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

export default InlineMonoText;
