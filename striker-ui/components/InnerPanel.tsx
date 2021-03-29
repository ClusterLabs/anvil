import { ReactNode } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  innerBody: {
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: TEXT,
    marginTop: '20px',
    marginBottom: '20px',
    paddingBottom: '10px',
  },
}));

const InnerPanel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return <Box className={classes.innerBody}>{children}</Box>;
};

export default InnerPanel;
