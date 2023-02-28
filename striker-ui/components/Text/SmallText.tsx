import { FC } from 'react';

import BodyText, { BodyTextProps } from './BodyText';

const SmallText: FC<BodyTextProps> = ({ ...bodyTextRestProps }) => (
  <BodyText {...{ variant: 'body2', ...bodyTextRestProps }} />
);

export default SmallText;
