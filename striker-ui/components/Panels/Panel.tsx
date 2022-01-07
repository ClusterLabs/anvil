import { ReactNode } from 'react';
import { GlobalStyles } from '@mui/material';
import { styled } from '@mui/material/styles';
import {
  BORDER_RADIUS,
  PANEL_BACKGROUND,
  TEXT,
} from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'Panel';

const classes = {
  paper: `${PREFIX}-paper`,
  square: `${PREFIX}-square`,
  topSquare: `${PREFIX}-topSquare`,
  bottomSquare: `${PREFIX}-bottomSquare`,
};

const StyledDiv = styled('div')(() => ({
  margin: '1em',
  position: 'relative',

  [`& .${classes.paper}`]: {
    padding: '2.1em',
    backgroundColor: PANEL_BACKGROUND,
    opacity: 0.8,
    zIndex: 999,
  },

  [`& .${classes.square}`]: {
    content: '""',
    position: 'absolute',
    width: '2.1em',
    height: '2.1em',
    border: '1px',
    borderColor: TEXT,
    borderWidth: '1px',
    borderRadius: BORDER_RADIUS,
    borderStyle: 'solid',
    padding: 0,
    margin: 0,
  },

  [`& .${classes.topSquare}`]: {
    top: '-.3em',
    left: '-.3em',
  },

  [`& .${classes.bottomSquare}`]: {
    bottom: '-.3em',
    right: '-.3em',
  },
}));

type Props = {
  children: ReactNode;
};

const styledScrollbars = (
  <GlobalStyles
    styles={{
      '*::-webkit-scrollbar': {
        width: '.6em',
      },
      '*::-webkit-scrollbar-track': {
        backgroundColor: PANEL_BACKGROUND,
      },
      '*::-webkit-scrollbar-thumb': {
        backgroundColor: TEXT,
        outline: '1px solid transparent',
        borderRadius: BORDER_RADIUS,
      },
    }}
  />
);

const Panel = ({ children }: Props): JSX.Element => {
  return (
    <StyledDiv>
      {styledScrollbars}
      <div className={`${classes.square} ${classes.topSquare}`} />
      <div className={`${classes.square} ${classes.bottomSquare}`} />
      <div className={classes.paper}>{children}</div>
    </StyledDiv>
  );
};

export default Panel;
