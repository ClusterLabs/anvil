import { useEffect, useMemo } from 'react';

import useCookieJar from './useCookieJar';

const useSessionExpiryCheck = (): void => {
  const { getSession } = useCookieJar();

  // Put session in memo to avoid triggering useEffect multiple times.
  const session = useMemo(() => getSession(), [getSession]);

  useEffect(() => {
    if (!session) return () => null;

    const { expires } = session;

    const deadline = new Date(expires).getTime();
    const nao = Date.now();
    const diff = deadline - nao;

    const tid = setTimeout(() => {
      if (!window) return;

      const { location } = window;
      const { pathname, search } = location;

      if (
        /^\/login/.test(pathname) ||
        (/^\/init/.test(pathname) && !search.includes('re=1'))
      )
        return;

      location.replace('/login');
    }, diff);

    if (window) {
      window.addEventListener('beforeunload', () => clearTimeout(tid), {
        once: true,
      });
    }

    return () => clearTimeout(tid);
  }, [session]);
};

export default useSessionExpiryCheck;
