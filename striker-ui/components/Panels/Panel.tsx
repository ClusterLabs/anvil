import { Box, GlobalStyles, styled } from '@mui/material';
import { FC } from 'react';

import {
  BORDER_RADIUS,
  PANEL_BACKGROUND,
  TEXT,
} from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'Panel';

const panelClasses = {
  paper: `${PREFIX}-paper`,
  square: `${PREFIX}-square`,
  topSquare: `${PREFIX}-topSquare`,
  bottomSquare: `${PREFIX}-bottomSquare`,
};

const StyledBox = styled(Box)(() => ({
  margin: '1em',
  position: 'relative',

  [`& .${panelClasses.paper}`]: {
    backgroundColor: `${PANEL_BACKGROUND}CC`,
    height: '100%',
    padding: '2.1em',
    position: 'relative',
    width: '100%',
    zIndex: 10,
  },

  [`& .${panelClasses.square}`]: {
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

  [`& .${panelClasses.topSquare}`]: {
    top: '-.3em',
    left: '-.3em',
  },

  [`& .${panelClasses.bottomSquare}`]: {
    bottom: '-.3em',
    right: '-.3em',
  },
}));

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
  className: rootClassName,
  paperProps: { className: paperClassName, ...restPaperProps } = {},
  sx: rootSx,
  ...restRootProps
}) => (
  <StyledBox className={rootClassName} sx={rootSx} {...restRootProps}>
    {styledScrollbars}
    <Box className={`${panelClasses.square} ${panelClasses.topSquare}`} />
    <Box className={`${panelClasses.square} ${panelClasses.bottomSquare}`} />
    <Box
      {...restPaperProps}
      className={`${panelClasses.paper} ${paperClassName}`}
    >
      {children}
    </Box>
  </StyledBox>
);

export { panelClasses };

export default Panel;
