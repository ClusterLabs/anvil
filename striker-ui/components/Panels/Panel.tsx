import { FC } from 'react';
import { Box, GlobalStyles, PaperProps, styled } from '@mui/material';

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

const StyledBox = styled(Box)(() => ({
  margin: '1em',
  position: 'relative',

  [`& .${classes.paper}`]: {
    backgroundColor: PANEL_BACKGROUND,
    height: '100%',
    opacity: 0.8,
    padding: '2.1em',
    position: 'relative',
    width: '100%',
    zIndex: 10,
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

type PanelProps = PaperProps;

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

const Panel: FC<PanelProps> = ({
  children,
  classes: rootClasses,
  className: rootClassName,
  sx: rootSx,
  ...restRootProps
}) => (
  <StyledBox
    {...{
      classes: rootClasses,
      className: rootClassName,
      sx: rootSx,
      ...restRootProps,
    }}
  >
    {styledScrollbars}
    <div className={`${classes.square} ${classes.topSquare}`} />
    <div className={`${classes.square} ${classes.bottomSquare}`} />
    <div className={classes.paper}>{children}</div>
  </StyledBox>
);

export default Panel;
