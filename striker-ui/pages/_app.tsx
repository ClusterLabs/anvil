import { CacheProvider, EmotionCache } from '@emotion/react';
import { ThemeProvider } from '@mui/material';
import { AppProps } from 'next/app';
import { CookiesProvider } from 'react-cookie';

import createEmotionCache from '../lib/create_emotion_cache/createEmotionCache';
import theme from '../theme';
import '../styles/globals.css';

import useSessionExpiryCheck from '../hooks/useSessionExpiryCheck';

const clientSideEmotionCache = createEmotionCache();

interface MyAppProps extends AppProps {
  emotionCache?: EmotionCache;
}

/**
 * Wraps the actual page component (`Component`).
 *
 * It allows react hooks to access app-wide providers that are included in the
 * `App` component. For example, the `useSessionExpiryCheck()` hook requires the
 * `useCookies()` hook from the `react-cookie` package, which requires the
 * `<CookiesProvider />`.
 */
const PageWrapper: React.FC<MyAppProps> = ({ Component, pageProps }) => {
  useSessionExpiryCheck();

  return <Component {...pageProps} />;
};

const App: React.FC<MyAppProps> = (props) => {
  const { emotionCache = clientSideEmotionCache } = props;

  return (
    <CacheProvider value={emotionCache}>
      <ThemeProvider theme={theme}>
        <CookiesProvider>
          <PageWrapper {...props} />
        </CookiesProvider>
      </ThemeProvider>
    </CacheProvider>
  );
};

export default App;
