import { LinearProgress } from '@mui/material';
import { styled } from '@mui/material/styles';
import {
  PANEL_BACKGROUND,
  BORDER_RADIUS,
} from '../../lib/consts/DEFAULT_THEME';

const BorderLinearProgress = styled(LinearProgress)({
  height: '1em',
  borderRadius: BORDER_RADIUS,
  backgroundColor: PANEL_BACKGROUND,
});

export default BorderLinearProgress;
