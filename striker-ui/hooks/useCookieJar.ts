import { useCallback, useEffect, useState } from 'react';

import useIsFirstRender from './useIsFirstRender';

const useCookieJar = (): {
  cookieJar: CookieJar;
  buildCookieJar: () => CookieJar;
  getCookie: <T>(key: string) => T | undefined;
  getSession: () => SessionCookie | undefined;
  getSessionUser: () => SessionCookieUser | undefined;
} => {
  const isFirstRender = useIsFirstRender();

  const [cookieJar, setCookieJar] = useState<CookieJar>({});

  const buildCookieJar = useCallback(() => {
    const lines = document.cookie.split(/\s*;\s*/);

    const jar = lines.reduce<CookieJar>((previous, line) => {
      const [key, value] = line.split('=', 2);

      const decoded = decodeURIComponent(value);

      let result: unknown;

      if (decoded.startsWith('j:')) {
        try {
          result = JSON.parse(decoded.substring(2));
        } catch (error) {
          result = value;
        }
      } else {
        result = value;
      }

      previous[key] = result;

      return previous;
    }, {});

    return jar;
  }, []);

  const getCookie = useCallback(
    <T>(key: string, prefix = 'suiapi.') =>
      cookieJar[`${prefix}${key}`] as T | undefined,
    [cookieJar],
  );

  const getSession = useCallback(
    () => getCookie<SessionCookie>('session'),
    [getCookie],
  );

  const getSessionUser = useCallback(() => getSession()?.user, [getSession]);

  useEffect(() => {
    if (isFirstRender) {
      setCookieJar(buildCookieJar());
    }
  }, [buildCookieJar, isFirstRender]);

  return {
    cookieJar,
    buildCookieJar,
    getCookie,
    getSession,
    getSessionUser,
  };
};

export default useCookieJar;
