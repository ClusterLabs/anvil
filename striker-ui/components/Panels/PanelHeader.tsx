import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

const PanelHeader = styled(MuiBox)({
  alignItems: 'center',
  display: 'flex',
  flexDirection: 'row',
  marginBottom: '1em',
  width: '100%',
  '& > :first-child': { flexGrow: 1 },
  '& > :not(:first-child, :last-child)': {
    marginRight: '.3em',
  },
});

export default PanelHeader;
