import { IconButton as MUIIconButton, styled } from '@mui/material';

import {
  BLACK,
  BORDER_RADIUS,
  GREY,
  TEXT,
} from '../../lib/consts/DEFAULT_THEME';

const IconButton = styled(MUIIconButton)({
  borderRadius: BORDER_RADIUS,
  backgroundColor: GREY,
  '&:hover': {
    backgroundColor: TEXT,
  },
  color: BLACK,
});

export default IconButton;
