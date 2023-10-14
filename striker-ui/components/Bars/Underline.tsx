import { Box, styled } from '@mui/material';

import { BORDER_RADIUS, DISABLED } from '../../lib/consts/DEFAULT_THEME';

const Underline = styled(Box)({
  backgroundColor: DISABLED,
  borderRadius: BORDER_RADIUS,
  display: 'block',
  height: '4px',
  position: 'relative',
});

export default Underline;
