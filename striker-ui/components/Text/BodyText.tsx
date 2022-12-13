import { FC, ReactNode } from 'react';
import {
  Typography as MUITypography,
  TypographyProps as MUITypographyProps,
} from '@mui/material';

import { BLACK, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

type BodyTextOptionalProps = {
  inverted?: boolean;
  monospaced?: boolean;
  selected?: boolean;
  text?: null | ReactNode | string;
};

type BodyTextProps = MUITypographyProps & BodyTextOptionalProps;

const BODY_TEXT_CLASS_PREFIX = 'BodyText';

const BODY_TEXT_DEFAULT_PROPS: Required<BodyTextOptionalProps> = {
  inverted: false,
  monospaced: false,
  selected: true,
  text: null,
};

const BODY_TEXT_CLASSES = {
  inverted: `${BODY_TEXT_CLASS_PREFIX}-inverted`,
  monospaced: `${BODY_TEXT_CLASS_PREFIX}-monospaced`,
  selected: `${BODY_TEXT_CLASS_PREFIX}-selected`,
  unselected: `${BODY_TEXT_CLASS_PREFIX}-unselected`,
};

const buildBodyTextClasses = ({
  isInvert,
  isMonospace,
  isSelect,
}: {
  isInvert?: boolean;
  isMonospace?: boolean;
  isSelect?: boolean;
}) => {
  const bodyTextClasses: string[] = [];

  if (isInvert) {
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
  inverted = BODY_TEXT_DEFAULT_PROPS.inverted,
  monospaced = BODY_TEXT_DEFAULT_PROPS.monospaced,
  selected = BODY_TEXT_DEFAULT_PROPS.selected,
  sx,
  text = BODY_TEXT_DEFAULT_PROPS.text,
  ...muiTypographyRestProps
}) => (
  <MUITypography
    {...{
      className: `${buildBodyTextClasses({
        isInvert: inverted,
        isMonospace: monospaced,
        isSelect: selected,
      })} ${className}`,
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
    {text ?? children}
  </MUITypography>
);

BodyText.defaultProps = BODY_TEXT_DEFAULT_PROPS;

export type { BodyTextProps };

export default BodyText;
