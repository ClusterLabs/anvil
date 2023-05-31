import { FC } from 'react';

import { BodyTextProps } from './BodyText';
import SmallText from './SmallText';

const MonoText: FC<BodyTextProps> = ({ sx, ...bodyTextRestProps }) => (
  <SmallText
    monospaced
    sx={{ alignItems: 'center', display: 'flex', height: '100%', ...sx }}
    {...bodyTextRestProps}
  />
);

export default MonoText;
