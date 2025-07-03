import muiGridClasses from '@mui/material/Grid2/grid2Classes';
import styled from '@mui/material/styles/styled';

const FormScrollBox = styled('div')({
  [`& > .${muiGridClasses.container}:first-child`]: {
    maxHeight: '60vh',
    overflowX: 'hidden',
    overflowY: 'scroll',
    paddingRight: '.4em',
    paddingTop: '.6em',
  },
});

export default FormScrollBox;
