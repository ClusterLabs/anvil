import { ReactNode } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  innerHeader: {
    position: 'relative',
    padding: '0 0.7em',
  },
  header: {
    top: '-0.3em',
    left: '-0.3em',
    padding: '1.4em 0',
    position: 'absolute',
    content: '""',
    borderColor: DIVIDER,
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    width: '100%',
  },
}));

const PanelHeader = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return (
    <Box className={classes.innerHeader} whiteSpace="pre-wrap">
      <div className={classes.header} />
      {children}
    </Box>
  );
};

export default PanelHeader;
