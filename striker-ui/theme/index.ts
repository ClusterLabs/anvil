import createTheme from '@mui/material/styles/createTheme';
import { Theme } from '@mui/material/styles/createThemeNoVars';
import { switchClasses } from '@mui/material/Switch';

import '@fontsource/roboto-condensed/300.css';
import '@fontsource/roboto-condensed/400.css';
import '@fontsource/roboto-condensed/700.css';

import '@fontsource/source-code-pro/300.css';
import '@fontsource/source-code-pro/400.css';
import '@fontsource/source-code-pro/700.css';

import {
  PANEL_BACKGROUND,
  TEXT,
  PURPLE,
  BLUE,
  DISABLED,
  BORDER_RADIUS,
} from '../lib/consts/DEFAULT_THEME';

const theme: Theme = createTheme({
  palette: {
    primary: {
      main: PANEL_BACKGROUND,
    },
    secondary: {
      main: TEXT,
    },
    background: {
      paper: PANEL_BACKGROUND,
    },
  },
  typography: {
    fontFamily: ['"Roboto Condensed"', '"Source Code Pro"'].join(','),
    fontWeightRegular: 200,
    fontSize: 14,
  },
  components: {
    MuiSwitch: {
      styleOverrides: {
        switchBase: {
          // Controls default (unchecked) color for the thumb
          color: TEXT,
        },
        root: {
          padding: 8,
        },
        track: {
          borderRadius: BORDER_RADIUS,
          border: 3,
          backgroundColor: PURPLE,
          opacity: 1,
          [`.${switchClasses.checked}.${switchClasses.checked} + &`]: {
            // Controls checked color for the track
            backgroundColor: BLUE,
            opacity: 1,
          },
          [`.${switchClasses.disabled}.${switchClasses.disabled} + &`]: {
            backgroundColor: DISABLED,
          },
        },
        thumb: {
          color: TEXT,
          borderRadius: BORDER_RADIUS,
        },
      },
    },
  },
});

export default theme;
