import { FC, useMemo } from 'react';

import { BodyTextProps } from './BodyText';
import SmallText from './SmallText';

const InlineMonoText: FC<BodyTextProps> = ({
  edge,
  sx,
  ...bodyTextRestProps
}) => {
  const paddingLeft = useMemo(() => (edge === 'start' ? 0 : undefined), [edge]);

  const paddingRight = useMemo(() => (edge === 'end' ? 0 : undefined), [edge]);

  const combinedSx: BodyTextProps['sx'] = useMemo(
    () => ({
      display: 'inline',
      padding: '.1rem .3rem',
      paddingLeft,
      paddingRight,

      ...sx,
    }),
    [paddingLeft, paddingRight, sx],
  );

  return <SmallText monospaced sx={combinedSx} {...bodyTextRestProps} />;
};

export default InlineMonoText;
