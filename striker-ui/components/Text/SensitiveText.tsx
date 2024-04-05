import { Box, styled } from '@mui/material';
import { createElement, FC, useMemo, useState } from 'react';

import { BORDER_RADIUS, EERIE_BLACK } from '../../lib/consts/DEFAULT_THEME';

import BodyText from './BodyText';
import MonoText from './MonoText';

const BaseStyle = styled(Box)({
  backgroundColor: EERIE_BLACK,
  borderRadius: BORDER_RADIUS,
  color: EERIE_BLACK,
  display: 'inline-flex',
  padding: '0 .6em',
  width: 'fit-content',

  ':focus': {
    color: 'unset',
  },
});

const SensitiveText: FC<SensitiveTextProps> = ({
  children,
  monospaced = false,
  revealInitially = false,
  textProps,
}) => {
  const [reveal, setReveal] = useState<boolean>(revealInitially);

  const content = useMemo(() => {
    if (typeof children !== 'string') return children;

    const elementType = monospaced ? MonoText : BodyText;

    return createElement(elementType, textProps, children);
  }, [children, monospaced, textProps]);

  return (
    <BaseStyle
      component="div"
      onBlur={() => setReveal(false)}
      onFocus={() => setReveal(true)}
      tabIndex={0}
    >
      {reveal ? content : '*****'}
    </BaseStyle>
  );
};

export default SensitiveText;
