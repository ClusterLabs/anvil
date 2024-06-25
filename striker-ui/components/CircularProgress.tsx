import { CircularProgress as MuiCircularProgress, styled } from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

const CircularProgress = styled(MuiCircularProgress)({
  color: GREY,
});

export default CircularProgress;
