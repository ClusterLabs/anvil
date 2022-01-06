import { styled } from '@mui/material/styles';
import { CircularProgress } from '@mui/material';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

const PREFIX = 'Spinner';

const classes = {
  spinner: `${PREFIX}-spinner`,
};

const StyledDiv = styled('div')(() => ({
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  marginTop: '3em',

  [`& .${classes.spinner}`]: {
    color: TEXT,
  },
}));

const Spinner = (): JSX.Element => {
  return (
    <StyledDiv>
      <CircularProgress variant="indeterminate" className={classes.spinner} />
    </StyledDiv>
  );
};

export default Spinner;
