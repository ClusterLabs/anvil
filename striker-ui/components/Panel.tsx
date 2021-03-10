import { ReactNode } from 'react';
import { Paper, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  rectangle: {
    width: '30px',
    height: '30px',
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: TEXT,
  },
  paper: {
    opacity: 0.7,
    padding: 10,
  },
}));

const Panel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return (
    <>
      <Box display="flex" justifyContent="flex-start">
        <Box className={classes.rectangle} />
      </Box>
      <Paper className={classes.paper}>{children}</Paper>
      <Box display="flex" justifyContent="flex-end">
        <Box className={classes.rectangle} />
      </Box>
    </>
  );
};

export default Panel;
