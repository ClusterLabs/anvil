import { FC, ReactNode, useMemo } from 'react';
import {
  Typography as MUITypography,
  TypographyProps as MUITypographyProps,
} from '@mui/material';

import { BLACK, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

type BodyTextOptionalProps = {
  inheritColour?: boolean;
  inverted?: boolean;
  monospaced?: boolean;
  selected?: boolean;
  text?: null | ReactNode | string;
};

type BodyTextProps = MUITypographyProps & BodyTextOptionalProps;

const BODY_TEXT_CLASS_PREFIX = 'BodyText';

const BODY_TEXT_DEFAULT_PROPS: Required<BodyTextOptionalProps> = {
  inheritColour: false,
  inverted: false,
  monospaced: false,
  selected: true,
  text: null,
};

const BODY_TEXT_CLASSES = {
  inheritColour: `${BODY_TEXT_CLASS_PREFIX}-inherit-colour`,
  inverted: `${BODY_TEXT_CLASS_PREFIX}-inverted`,
  monospaced: `${BODY_TEXT_CLASS_PREFIX}-monospaced`,
  selected: `${BODY_TEXT_CLASS_PREFIX}-selected`,
  unselected: `${BODY_TEXT_CLASS_PREFIX}-unselected`,
};

const buildBodyTextClasses = ({
  isInheritColour,
  isInvert,
  isMonospace,
  isSelect,
}: {
  isInheritColour?: boolean;
  isInvert?: boolean;
  isMonospace?: boolean;
  isSelect?: boolean;
}) => {
  const bodyTextClasses: string[] = [];

  if (isInheritColour) {
    bodyTextClasses.push(BODY_TEXT_CLASSES.inheritColour);
  } else if (isInvert) {
    bodyTextClasses.push(BODY_TEXT_CLASSES.inverted);
  } else if (isSelect) {
    bodyTextClasses.push(BODY_TEXT_CLASSES.selected);
  } else {
    bodyTextClasses.push(BODY_TEXT_CLASSES.unselected);
  }

  if (isMonospace) {
    bodyTextClasses.push(BODY_TEXT_CLASSES.monospaced);
  }

  return bodyTextClasses.join(' ');
};

const BodyText: FC<BodyTextProps> = ({
  children,
  className,
  inheritColour: isInheritColour = BODY_TEXT_DEFAULT_PROPS.inheritColour,
  inverted: isInvert = BODY_TEXT_DEFAULT_PROPS.inverted,
  monospaced: isMonospace = BODY_TEXT_DEFAULT_PROPS.monospaced,
  selected: isSelect = BODY_TEXT_DEFAULT_PROPS.selected,
  sx,
  text = BODY_TEXT_DEFAULT_PROPS.text,
  ...muiTypographyRestProps
}) => {
  const baseClassName = useMemo(
    () =>
      buildBodyTextClasses({
        isInheritColour,
        isInvert,
        isMonospace,
        isSelect,
      }),
    [isInheritColour, isInvert, isMonospace, isSelect],
  );
  const content = useMemo(() => text ?? children, [children, text]);

  return (
    <MUITypography
      {...{
        className: `${baseClassName} ${className}`,
        variant: 'subtitle1',
        ...muiTypographyRestProps,
        sx: {
          [`&.${BODY_TEXT_CLASSES.inverted}`]: {
            color: BLACK,
          },

          [`&.${BODY_TEXT_CLASSES.monospaced}`]: {
            fontFamily: 'Source Code Pro',
            fontWeight: 400,
          },

          [`&.${BODY_TEXT_CLASSES.selected}`]: {
            color: TEXT,
          },

          [`&.${BODY_TEXT_CLASSES.unselected}`]: {
            color: UNSELECTED,
          },

          ...sx,
        },
      }}
    >
      {content}
    </MUITypography>
  );
};

BodyText.defaultProps = BODY_TEXT_DEFAULT_PROPS;

export type { BodyTextProps };

export default BodyText;
