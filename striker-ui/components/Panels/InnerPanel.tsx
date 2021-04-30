import { ReactNode } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  innerBody: {
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: DIVIDER,
    marginTop: '1.4em',
    marginBottom: '1.4em',
    paddingBottom: '0.7em',
    position: 'relative',
  },
}));

const InnerPanel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return <Box className={classes.innerBody}>{children}</Box>;
};

export default InnerPanel;
