import { useEffect } from 'react';
import { AppProps } from 'next/app';
import { ThemeProvider } from '@material-ui/core/styles';
import theme from '../theme';
import '../styles/globals.css';

const App = ({ Component, pageProps }: AppProps): JSX.Element => {
  // This hook is for ensuring the styling is in sync between client and server
  useEffect(() => {
    // Remove the server-side injected CSS.
    const jssStyles = document.querySelector('#jss-server-side');
    if (jssStyles) {
      jssStyles.parentElement?.removeChild(jssStyles);
    }
  }, []);

  // eslint-disable-next-line react/jsx-props-no-spreading
  return (
    <ThemeProvider theme={theme}>
      <Component
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...pageProps}
      />
    </ThemeProvider>
  );
};

export default App;
