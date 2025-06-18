import MuiLink from '@mui/material/Link';
import styled from '@mui/material/styles/styled';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

const StyledLink = styled(MuiLink)({
  color: TEXT,
  textDecorationColor: GREY,
});

const Link: React.FC<LinkProps> = (props) => {
  const { children, ...restProps } = props;

  return (
    <StyledLink underline="always" variant="subtitle1" {...restProps}>
      {children}
    </StyledLink>
  );
};

export default Link;
