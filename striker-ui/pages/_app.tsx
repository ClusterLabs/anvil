import { AppProps } from 'next/app';
import { ThemeProvider } from '@mui/material';
import { CacheProvider, EmotionCache } from '@emotion/react';

import createEmotionCache from '../lib/create_emotion_cache/createEmotionCache';
import theme from '../theme';
import '../styles/globals.css';

import useSessionExpiryCheck from '../hooks/useSessionExpiryCheck';

const clientSideEmotionCache = createEmotionCache();

interface MyAppProps extends AppProps {
  emotionCache?: EmotionCache;
}

const App = ({
  Component,
  emotionCache = clientSideEmotionCache,
  pageProps,
}: MyAppProps): React.ReactElement => {
  useSessionExpiryCheck();

  return (
    <CacheProvider value={emotionCache}>
      <ThemeProvider theme={theme}>
        <Component {...pageProps} />
      </ThemeProvider>
    </CacheProvider>
  );
};

export default App;
