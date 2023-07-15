import { Button, styled } from '@mui/material';
import {
  createElement,
  FC,
  ReactElement,
  ReactNode,
  useCallback,
  useMemo,
  useState,
} from 'react';

import { BORDER_RADIUS, EERIE_BLACK } from '../../lib/consts/DEFAULT_THEME';

import BodyText from './BodyText';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import MonoText from './MonoText';

const InlineButton = styled(Button)({
  backgroundColor: EERIE_BLACK,
  borderRadius: BORDER_RADIUS,
  minWidth: 'initial',
  padding: '0 .6em',
  textTransform: 'none',

  ':hover': {
    backgroundColor: `${EERIE_BLACK}F0`,
  },
});

const SensitiveText: FC<SensitiveTextProps> = ({
  children,
  inline: isInline = false,
  monospaced: isMonospaced = false,
  revealButtonProps,
  revealInitially: isRevealInitially = false,
  textLineHeight = 2.8,
  textProps,
}) => {
  const [isReveal, setIsReveal] = useState<boolean>(isRevealInitially);

  const clickEventHandler = useCallback(() => {
    setIsReveal((previous) => !previous);
  }, []);

  const textSxLineHeight = useMemo<number | string | undefined>(
    () => (isInline ? undefined : textLineHeight || undefined),
    [isInline, textLineHeight],
  );

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
                  lineHeight: textSxLineHeight,
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
      content = createElement(
        textElementType,
        {
          sx: {
            lineHeight: textSxLineHeight,
          },
          ...textProps,
        },
        '*****',
      );
    }

    return content;
  }, [children, isReveal, textElementType, textProps, textSxLineHeight]);
  const rootElement = useMemo<ReactElement>(
    () =>
      isInline ? (
        <InlineButton onClick={clickEventHandler}>
          {contentElement}
        </InlineButton>
      ) : (
        <FlexBox row spacing=".5em">
          {contentElement}
          <IconButton
            edge="end"
            mapPreset="visibility"
            onClick={clickEventHandler}
            state={String(isReveal)}
            sx={{ marginRight: '-.2em', padding: '.2em' }}
            variant="normal"
            {...revealButtonProps}
          />
        </FlexBox>
      ),
    [clickEventHandler, contentElement, revealButtonProps, isInline, isReveal],
  );

  return rootElement;
};

export default SensitiveText;
