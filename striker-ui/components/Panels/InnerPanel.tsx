import { ReactNode } from 'react';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const useStyles = makeStyles(() => ({
  innerBody: {
    borderWidth: '1px',
    borderRadius: BORDER_RADIUS,
    borderStyle: 'solid',
    borderColor: DIVIDER,
    marginTop: '1.4em',
    marginBottom: '1.4em',
    paddingBottom: '.7em',
    position: 'relative',
  },
}));

const InnerPanel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return <Box className={classes.innerBody}>{children}</Box>;
};

export default InnerPanel;
