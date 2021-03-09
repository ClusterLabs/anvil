import createMuiTheme, { Theme } from '@material-ui/core/styles/createMuiTheme';
import {
  PANEL_BACKGROUND,
  TEXT,
  PURPLE_OFF,
  RED_ON,
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
    fontFamily: 'Roboto',
    fontSize: 14,
  },
  overrides: {
    MuiSwitch: {
      root: {
        padding: 8,
      },
      track: {
        borderRadius: 0,
        backgroundColor: PURPLE_OFF,
        '$checked$checked + &': {
          // Controls checked color for the track
          backgroundColor: RED_ON,
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
