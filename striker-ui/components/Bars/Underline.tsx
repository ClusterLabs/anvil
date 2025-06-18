import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

import { BORDER_RADIUS, DISABLED } from '../../lib/consts/DEFAULT_THEME';

const Underline = styled(MuiBox)({
  backgroundColor: DISABLED,
  borderRadius: BORDER_RADIUS,
  display: 'block',
  height: '4px',
  position: 'relative',
});

export default Underline;
