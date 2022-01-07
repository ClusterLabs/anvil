import { Typography } from '@mui/material';
import { styled } from '@mui/material/styles';
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

interface TextProps {
  text: string;
  selected?: boolean;
}

const BodyText = ({ text, selected }: TextProps): JSX.Element => {
  return (
    <StyledTypography
      variant="subtitle1"
      className={selected ? classes.selected : classes.unselected}
    >
      {text}
    </StyledTypography>
  );
};

BodyText.defaultProps = {
  selected: true,
};

export default BodyText;
