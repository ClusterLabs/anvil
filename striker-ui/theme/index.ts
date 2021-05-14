import createMuiTheme, { Theme } from '@material-ui/core/styles/createMuiTheme';
import {
  PANEL_BACKGROUND,
  TEXT,
  PURPLE,
  BLUE,
  DISABLED,
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
        color: TEXT,
      },
      root: {
        padding: 8,
      },
      track: {
        borderRadius: 3,
        border: 3,
        backgroundColor: PURPLE,
        opacity: 1,
        '$checked$checked + &': {
          // Controls checked color for the track
          backgroundColor: BLUE,
          opacity: 1,
        },
        '$disabled$disabled + &': {
          backgroundColor: DISABLED,
        },
      },
      thumb: {
        color: TEXT,
        borderRadius: 3,
      },
    },
  },
});

export default theme;
