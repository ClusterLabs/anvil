import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { TEXT } from '../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles(() => ({
  innerBody: {
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: TEXT,
    marginTop: '5px',
    marginLeft: '5px',
    paddinLeft: '5px',
  },
  innerHeader: {
    width: '100%',
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: TEXT,
  },
}));

const InnerPanel = (): JSX.Element => {
  const classes = useStyles();

  return <Box className={classes.innerBody}>inner body</Box>;
};

export default InnerPanel;
