import createMuiTheme, { Theme } from '@material-ui/core/styles/createMuiTheme';
import {
  PANEL_BACKGROUND,
  TEXT,
  PURPLE_OFF,
  BLUE,
} from '../lib/consts/DEFAULT_THEME';

const theme: Theme = createMuiTheme({
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
    fontFamily: 'Roboto Condensed',
    fontWeightRegular: 200,
    fontSize: 14,
  },
  overrides: {
    MuiSwitch: {
      switchBase: {
        // Controls default (unchecked) color for the thumb
        color: '#fff',
      },
      root: {
        padding: 8,
      },
      track: {
        borderRadius: 0,
        border: 3,
        backgroundColor: PURPLE_OFF,
        '$checked$checked + &': {
          // Controls checked color for the track
          backgroundColor: BLUE,
        },
        '&$checked + $track': {
          opacity: 1,
        },
      },
      thumb: {
        color: TEXT,
        borderRadius: 0,
      },
    },
  },
});

export default theme;
