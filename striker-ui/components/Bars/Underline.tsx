import { Box as MuiBox, styled } from '@mui/material';

import { BORDER_RADIUS, DISABLED } from '../../lib/consts/DEFAULT_THEME';

const Underline = styled(MuiBox)({
  backgroundColor: DISABLED,
  borderRadius: BORDER_RADIUS,
  display: 'block',
  height: '4px',
  position: 'relative',
});

export default Underline;
