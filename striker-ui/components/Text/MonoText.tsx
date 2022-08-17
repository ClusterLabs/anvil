import { FC } from 'react';

import { BodyTextProps } from './BodyText';
import SmallText from './SmallText';

type MonoTextProps = BodyTextProps;

const MonoText: FC<MonoTextProps> = ({ sx, ...bodyTextRestProps }) => (
  <SmallText
    monospaced
    sx={{ alignItems: 'center', display: 'flex', height: '100%', ...sx }}
    {...bodyTextRestProps}
  />
);

export type { MonoTextProps };

export default MonoText;
