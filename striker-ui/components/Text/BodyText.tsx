import { styled, Typography, TypographyProps } from '@mui/material';

import { TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'BodyText';

const classes = {
  selected: `${PREFIX}-selected`,
  unselected: `${PREFIX}-unselected`,
};

const StyledTypography = styled(Typography)(() => ({
  [`&.${classes.selected}`]: {
    color: TEXT,
  },

  [`&.${classes.unselected}`]: {
    color: UNSELECTED,
  },
}));

type BodyTextProps = TypographyProps & {
  text: string;
  selected?: boolean;
};

const BodyText = ({ sx, text, selected }: BodyTextProps): JSX.Element => {
  return (
    <StyledTypography
      {...{ sx }}
      className={selected ? classes.selected : classes.unselected}
      variant="subtitle1"
    >
      {text}
    </StyledTypography>
  );
};

BodyText.defaultProps = {
  selected: true,
};

export default BodyText;
