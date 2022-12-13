import { FC } from 'react';

import { BodyTextProps } from './BodyText';
import SmallText from './SmallText';

type InlineMonoTextProps = BodyTextProps;

const InlineMonoText: FC<InlineMonoTextProps> = ({
  sx,
  ...bodyTextRestProps
}) => (
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

export type { InlineMonoTextProps };

export default InlineMonoText;
