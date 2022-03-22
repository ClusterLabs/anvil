import { Box, styled } from '@mui/material';

const PanelHeader = styled(Box)({
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
