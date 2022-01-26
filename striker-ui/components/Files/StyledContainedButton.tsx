import { Button, ButtonProps, styled } from '@mui/material';

import { BLACK, GREY, TEXT } from '../../lib/consts/DEFAULT_THEME';

const StyledButton = styled(Button)({
  backgroundColor: TEXT,
  color: BLACK,
  textTransform: 'none',

  '&:hover': {
    backgroundColor: GREY,
  },
});

const StyledContainedButton = ({
  children,
  onClick,
  sx,
  type,
}: ButtonProps): JSX.Element => (
  <StyledButton {...{ onClick, sx, type }} variant="contained">
    {children}
  </StyledButton>
);

export default StyledContainedButton;
