import { Box as MuiBox, styled } from '@mui/material';

const DialogScrollBox = styled(MuiBox)({
  maxHeight: '60vh',
  overflowY: 'scroll',
  paddingRight: '.4em',
});

export default DialogScrollBox;
