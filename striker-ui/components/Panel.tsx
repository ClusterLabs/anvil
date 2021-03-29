import { ReactNode } from 'react';
// import { Paper, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { PANEL_BACKGROUND, TEXT } from '../lib/consts/DEFAULT_THEME';

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
    margin: 10,
    padding: 10,
    backgroundColor: PANEL_BACKGROUND,
    '&::before': {
      content: '""',
      position: 'absolute',
      top: '-10px',
      bottom: '-10px',
      width: '30px',
      height: '30px',
      border: '1px',
      borderColor: TEXT,
      borderWidth: '1px',
      borderRadius: '3px',
      borderStyle: 'solid',
    },
  },
}));

const Panel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return <div className={classes.paper}>{children}</div>;
};

export default Panel;
