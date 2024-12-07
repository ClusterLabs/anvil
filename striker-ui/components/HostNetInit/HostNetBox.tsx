import { Box, styled } from '@mui/material';

const deleteButtonOffset = '.5em';

const HostNetBox = styled(Box)(({ theme }) => ({
  display: 'grid',

  [theme.breakpoints.up('xs')]: {
    gridAutoColumns: `calc(100% - ${deleteButtonOffset})`,
  },

  [theme.breakpoints.up('sm')]: {
    gridAutoColumns: `calc(50% - ${deleteButtonOffset})`,
  },

  [theme.breakpoints.up('md')]: {
    gridAutoColumns: `calc(100% / 3 - ${deleteButtonOffset})`,
  },

  [theme.breakpoints.up('lg')]: {
    gridAutoColumns: `calc(25% - ${deleteButtonOffset})`,
  },

  gridAutoFlow: 'column',
  overflowX: 'scroll',
  scrollSnapType: 'x',

  '& > div': {
    scrollSnapAlign: 'start',
  },

  '& > :not(div:first-child)': {
    marginLeft: '1em',
  },
}));

export { deleteButtonOffset };

export default HostNetBox;
