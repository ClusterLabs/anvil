import { useCallback } from 'react';

import api from '../lib/api';
import handleAPIError from '../lib/handleAPIError';
import useProtectedState from './useProtectedState';

type ActiveFetchSetter<T> = (data: T) => void;

type ActiveFetcher = (url?: string) => void;

type ActiveFetchHookResponse = {
  fetch: ActiveFetcher;
  loading: boolean;
};

const useActiveFetch = <Data>(
  options: {
    onData?: ActiveFetchSetter<Data>;
    onError?: (emsg: Message) => void;
    url?: string;
  } = {},
): ActiveFetchHookResponse => {
  const { onError, onData, url: urlPrefix = '' } = options;

  const [loading, setLoading] = useProtectedState<boolean>(false);

  const fetch = useCallback<ActiveFetcher>(
    (urlPostfix = '') => {
      const url = `${urlPrefix}${urlPostfix}`;

      if (!url) return;

      setLoading(true);

      api
        .get<Data>(url)
        .then(({ data }) => {
          onData?.call(null, data);
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          onError?.call(null, emsg);
        })
        .finally(() => {
          setLoading(false);
        });
    },
    [urlPrefix, setLoading, onError, onData],
  );

  return { fetch, loading };
};

export default useActiveFetch;
