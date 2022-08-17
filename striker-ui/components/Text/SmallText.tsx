import { FC } from 'react';

import BodyText, { BodyTextProps } from './BodyText';

type SmallTextProps = BodyTextProps;

const SmallText: FC<SmallTextProps> = ({ ...bodyTextRestProps }) => (
  <BodyText {...{ variant: 'body2', ...bodyTextRestProps }} />
);

export type { SmallTextProps };

export default SmallText;
