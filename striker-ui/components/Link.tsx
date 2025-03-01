import { Link as MuiLink, styled } from '@mui/material';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

const BaseStyle = styled(MuiLink)({
  color: TEXT,
  textDecorationColor: GREY,
});

const Link: React.FC<LinkProps> = (props) => {
  const { children, ...restProps } = props;

  return (
    <BaseStyle underline="always" variant="subtitle1" {...restProps}>
      {children}
    </BaseStyle>
  );
};

export default Link;
