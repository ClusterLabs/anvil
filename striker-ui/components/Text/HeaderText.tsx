import {
  styled,
  Typography as MuiTypography,
  TypographyProps as MuiTypographyProps,
} from '@mui/material';

import { TEXT } from '../../lib/consts/DEFAULT_THEME';

const StyledTypography = styled(MuiTypography)({
  color: TEXT,
});

type HeaderTextOptionalPropsWithoutDefault = {
  text?: string;
};

type HeaderTextOptionalProps = HeaderTextOptionalPropsWithoutDefault;

type HeaderTextProps = MuiTypographyProps & HeaderTextOptionalProps;

const HeaderText: React.FC<HeaderTextProps> = ({
  text,
  // Dependants:
  children = text,

  ...restHeaderTextProps
}) => (
  <StyledTypography variant="h4" {...restHeaderTextProps}>
    {children}
  </StyledTypography>
);

export default HeaderText;
