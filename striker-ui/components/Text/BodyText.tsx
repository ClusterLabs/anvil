import { styled, Typography, TypographyProps } from '@mui/material';

import { BLACK, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'BodyText';

const classes = {
  inverted: `${PREFIX}-inverted`,
  selected: `${PREFIX}-selected`,
  unselected: `${PREFIX}-unselected`,
};

const StyledTypography = styled(Typography)(() => ({
  [`&.${classes.inverted}`]: {
    color: BLACK,
  },

  [`&.${classes.selected}`]: {
    color: TEXT,
  },

  [`&.${classes.unselected}`]: {
    color: UNSELECTED,
  },
}));

type BodyTextProps = TypographyProps & {
  inverted?: boolean;
  selected?: boolean;
  text: string;
};

const BodyText = ({
  inverted,
  selected,
  sx,
  text,
}: BodyTextProps): JSX.Element => {
  const buildBodyTextClasses = ({
    isInvert,
    isSelect,
  }: {
    isInvert?: boolean;
    isSelect?: boolean;
  }) => {
    let bodyTextClasses = '';

    if (isInvert) {
      bodyTextClasses += classes.inverted;
    } else if (isSelect) {
      bodyTextClasses += classes.selected;
    } else {
      bodyTextClasses += classes.unselected;
    }

    return bodyTextClasses;
  };

  return (
    <StyledTypography
      {...{ sx }}
      className={buildBodyTextClasses({
        isInvert: inverted,
        isSelect: selected,
      })}
      variant="subtitle1"
    >
      {text}
    </StyledTypography>
  );
};

BodyText.defaultProps = {
  inverted: false,
  selected: true,
};

export default BodyText;
