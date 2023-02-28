import { createElement, FC, ReactNode, useMemo, useState } from 'react';

import BodyText from './BodyText';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import MonoText from './MonoText';

const SensitiveText: FC<SensitiveTextProps> = ({
  children,
  monospaced: isMonospaced = false,
  revealInitially: isRevealInitially = false,
  textProps,
}) => {
  const [isReveal, setIsReveal] = useState<boolean>(isRevealInitially);

  const textElementType = useMemo(
    () => (isMonospaced ? MonoText : BodyText),
    [isMonospaced],
  );
  const contentElement = useMemo(() => {
    let content: ReactNode;

    if (isReveal) {
      content =
        typeof children === 'string'
          ? createElement(
              textElementType,
              {
                sx: {
                  lineHeight: 2.8,
                  maxWidth: '20em',
                  overflowY: 'scroll',
                  whiteSpace: 'nowrap',
                },
                ...textProps,
              },
              children,
            )
          : children;
    } else {
      content = createElement(textElementType, textProps, '*****');
    }

    return content;
  }, [children, isReveal, textElementType, textProps]);

  return (
    <FlexBox row spacing=".5em">
      {contentElement}
      <IconButton
        edge="end"
        mapPreset="visibility"
        onClick={() => {
          setIsReveal((previous) => !previous);
        }}
        state={String(isReveal)}
        sx={{ marginRight: '-.2em', padding: '.2em' }}
        variant="normal"
      />
    </FlexBox>
  );
};

export default SensitiveText;
