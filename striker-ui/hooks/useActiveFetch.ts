import { AxiosRequestConfig } from 'axios';
import { useCallback, useState } from 'react';

import api from '../lib/api';
import handleAPIError from '../lib/handleAPIError';

type ActiveFetchSetter<ResData> = (data: ResData) => void;

type ActiveFetcher<ReqData> = (
  url?: string,
  config?: AxiosRequestConfig<ReqData>,
) => void;

type ActiveFetchHookResponse<ReqData> = {
  fetch: ActiveFetcher<ReqData>;
  loading: boolean;
};

const useActiveFetch = <ResData, ReqData = unknown>(
  options: {
    config?: AxiosRequestConfig<ReqData>;
    onData?: ActiveFetchSetter<ResData>;
    onError?: (emsg: Message) => void;
    url?: string;
  } = {},
): ActiveFetchHookResponse<ReqData> => {
  const { config: baseConfig, onError, onData, url: urlPrefix = '' } = options;

  const [loading, setLoading] = useState<boolean>(false);

  const fetch = useCallback<ActiveFetcher<ReqData>>(
    (urlPostfix = '', config) => {
      const url = `${urlPrefix}${urlPostfix}`;

      if (!url) return;

      setLoading(true);

      api
        .get<ResData>(url, { ...baseConfig, ...config })
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
    [urlPrefix, baseConfig, onData, onError],
  );

  return { fetch, loading };
};

export default useActiveFetch;
