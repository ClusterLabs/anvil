import {
  LinearProgress as MuiLinearProgress,
  linearProgressClasses as muiLinearProgressClasses,
  styled,
} from '@mui/material';

import { BORDER_RADIUS } from '../../lib/consts/DEFAULT_THEME';

const BorderLinearProgress = styled(MuiLinearProgress)({
  backgroundColor: 'transparent',
  borderRadius: BORDER_RADIUS,
  height: '1em',

  [`& .${muiLinearProgressClasses.bar}`]: {
    borderRadius: BORDER_RADIUS,
  },
});

export default BorderLinearProgress;
