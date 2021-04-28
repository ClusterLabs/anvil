import { ReactNode } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { PANEL_BACKGROUND, TEXT, DIVIDER } from '../lib/consts/DEFAULT_THEME';

type Props = {
  children: ReactNode;
};

const decorationBoxProps = {
  content: '""',
  position: 'absolute',
  width: '30px',
  height: '30px',
  border: '1px',
  borderColor: TEXT,
  borderWidth: '1px',
  borderRadius: '3px',
  borderStyle: 'solid',
  padding: 0,
  margin: 0,
  zIndex: -1,
};

const useStyles = makeStyles(() => ({
  rectangle: {
    width: '30px',
    height: '30px',
    borderWidth: '1px',
    borderRadius: '3px',
    borderStyle: 'solid',
    borderColor: DIVIDER,
  },
  paper: {
    margin: 10,
    padding: '30px',
    backgroundColor: PANEL_BACKGROUND,
    position: 'relative',
    zIndex: 999,
    '&::before': {
      ...decorationBoxProps,
      top: '-5px',
      left: '-5px',
    },
    '&::after': {
      ...decorationBoxProps,
      bottom: '-5px',
      right: '-5px',
    },
  },
}));

const Panel = ({ children }: Props): JSX.Element => {
  const classes = useStyles();

  return <div className={classes.paper}>{children}</div>;
};

export default Panel;
