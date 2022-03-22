import { EmotionCache } from '@emotion/react';
import createCache from '@emotion/cache';

const createEmotionCache = (): EmotionCache => createCache({ key: 'css' });

export default createEmotionCache;
