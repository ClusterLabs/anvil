import MuiListItemButton from '@mui/material/ListItemButton';
import styled from '@mui/material/styles/styled';

import { BORDER_RADIUS } from '../../lib/consts/DEFAULT_THEME';

const ListItemButton = styled(MuiListItemButton)({
  borderRadius: BORDER_RADIUS,
});

export default ListItemButton;
