import createMuiTheme, { Theme } from '@material-ui/core/styles/createMuiTheme';
import { PANEL_BACKGROUND } from '../lib/consts/DEFAULT_THEME';

const theme: Theme = createMuiTheme({
  palette: {
    primary: {
      main: '#343434',
      light: '#3E78B2',
    },
    secondary: {
      main: '#343434',
    },
    background: {
      paper: PANEL_BACKGROUND,
    },
  },
  typography: {
    fontSize: 14,
  },
  overrides: {
    MuiSwitch: {
      root: {
        padding: 8,
      },
      track: {
        borderRadius: 0,
      },
      thumb: {
        borderRadius: 0,
      },
    },
  },
});

export default theme;
