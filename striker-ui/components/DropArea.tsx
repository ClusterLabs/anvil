import { Box as MUIBox, styled } from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

const DropArea = styled(MUIBox)(() => ({
  borderColor: GREY,
  borderStyle: 'dashed',
  borderWidth: '4px',
  display: 'flex',
  flexDirection: 'column',
  padding: '.6em',

  '& > :not(:first-child)': {
    marginTop: '.3em',
  },
}));

export default DropArea;
