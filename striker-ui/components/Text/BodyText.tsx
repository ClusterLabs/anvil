import { useMemo } from 'react';
import {
  Typography as MuiTypography,
  TypographyProps as MuiTypographyProps,
} from '@mui/material';

import { BLACK, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

type BodyTextOptionalProps = {
  edge?: 'start' | 'end' | null;
  inheritColour?: boolean;
  inline?: boolean;
  inverted?: boolean;
  monospaced?: boolean;
  selected?: boolean;
  text?: null | React.ReactNode | string;
};

type BodyTextProps = MuiTypographyProps & BodyTextOptionalProps;

const BODY_TEXT_CLASS_PREFIX = 'BodyText';

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

const BodyText: React.FC<BodyTextProps> = ({
  className,
  inheritColour: isInheritColour = false,
  inline: isInline = false,
  inverted: isInvert = false,
  monospaced: isMonospace = false,
  selected: isSelect = true,
  sx,
  text = null,
  // Dependants:
  children = text,

  ...muiTypographyRestProps
}) => {
  const sxDisplay = useMemo<string | undefined>(
    () => (isInline ? 'inline' : undefined),
    [isInline],
  );

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

  return (
    <MuiTypography
      className={`${baseClassName} ${className}`}
      // TODO: change to non-title variant!
      variant="subtitle1"
      {...muiTypographyRestProps}
      sx={{
        display: sxDisplay,

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
      }}
    >
      {children}
    </MuiTypography>
  );
};

export type { BodyTextProps };

export default BodyText;
