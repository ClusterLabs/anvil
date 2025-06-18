import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

import { GREY } from '../lib/consts/DEFAULT_THEME';

const DropArea = styled(MuiBox)(() => ({
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
