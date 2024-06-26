import { Box, styled } from '@mui/material';
import { FC, useMemo, useState } from 'react';

import { BORDER_RADIUS, EERIE_BLACK } from '../../lib/consts/DEFAULT_THEME';

import BodyText, { BodyTextProps } from './BodyText';
import MonoText from './MonoText';
import SmallText from './SmallText';

const MAP_TO_WRAPPER_TYPE: Record<
  string,
  (<T extends BodyTextProps>(props: T) => React.ReactNode) | undefined
> = {
  body: (props) => <BodyText {...props} />,
  mono: (props) => <MonoText {...props} />,
  none: undefined,
  small: (props) => <SmallText {...props} />,
};

const BaseStyle = styled(Box)({
  backgroundColor: EERIE_BLACK,
  borderRadius: BORDER_RADIUS,
  color: EERIE_BLACK,
  cursor: 'pointer',
  display: 'inline-flex',
  padding: '0 .6em',
  width: 'fit-content',

  ':focus': {
    color: 'unset',
    cursor: 'text',
  },
});

const SensitiveText: FC<SensitiveTextProps> = ({
  children,
  revealInitially = false,
  wrapper = 'none',
  wrapperProps,
}) => {
  const [reveal, setReveal] = useState<boolean>(revealInitially);

  const content = useMemo<React.ReactNode>(() => {
    const cb = MAP_TO_WRAPPER_TYPE[wrapper];

    return cb ? cb({ ...wrapperProps, children }) : children;
  }, [children, wrapper, wrapperProps]);

  return (
    <BaseStyle
      component="span"
      onBlur={() => setReveal(false)}
      onFocus={() => setReveal(true)}
      tabIndex={0}
    >
      {reveal ? content : '*****'}
    </BaseStyle>
  );
};

export default SensitiveText;
