import { useEffect } from 'react';
import { useCookies } from 'react-cookie';

const useSessionExpiryCheck = (): void => {
  const [cookies] = useCookies(['suiapi.session']);

  const session: SessionCookie | undefined = cookies['suiapi.session'];

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
