import { ReactNode } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  innerHeader: {
    position: 'relative',
    padding: '0 10px',
    '&::before': {
      top: '-5px',
      left: '-5px',
      padding: '10px 0',
      position: 'absolute',
      content: '""',
      borderColor: TEXT,
      borderWidth: '1px',
      borderRadius: '3px',
      borderStyle: 'solid',
      width: '100%',
    },
  },
}));

const PanelHeader = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return (
    <Box className={classes.innerHeader} style={{ whiteSpace: 'pre-wrap' }}>
      {children}
    </Box>
  );
};

export default PanelHeader;
