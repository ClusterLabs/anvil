import { LinearProgress, linearProgressClasses, styled } from '@mui/material';

import { BORDER_RADIUS } from '../../lib/consts/DEFAULT_THEME';

const BorderLinearProgress = styled(LinearProgress)({
  backgroundColor: 'transparent',
  borderRadius: BORDER_RADIUS,
  height: '1em',

  [`& .${linearProgressClasses.bar}`]: {
    borderRadius: BORDER_RADIUS,
  },
});

export default BorderLinearProgress;
