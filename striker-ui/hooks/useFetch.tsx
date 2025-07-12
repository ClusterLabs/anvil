import { AxiosError, AxiosResponse } from 'axios';
import { useMemo } from 'react';
import useSWR, { BareFetcher, KeyedMutator, SWRConfiguration } from 'swr';

import api from '../lib/api';

type FetchHookResponse<
  ResData,
  AltResData = ResData,
  ReqData = unknown,
  Err extends Error = AxiosError<ReqData, ResData>,
> = {
  altData?: AltResData;
  data?: ResData;
  error?: Err;
  mutate: KeyedMutator<ResData>;
  loading: boolean;
  validating: boolean;
};

const useFetch = <
  ResData,
  AltResData = ResData,
  ReqData = unknown,
  Err extends Error = AxiosError<ReqData, ResData>,
>(
  url: string,
  options: SWRConfiguration<ResData, Err, BareFetcher<ResData>> & {
    mod?: (data: ResData) => AltResData;
    periodic?: boolean;
    timeout?: number;
  } = {},
): FetchHookResponse<ResData, AltResData, ReqData, Err> => {
  const {
    timeout = 5000,
    mod,
    periodic,
    // Depends on the above
    fetcher = async (l) => {
      const response = await api.get<
        ResData,
        AxiosResponse<ResData, ReqData>,
        ReqData
      >(l, {
        timeout,
      });

      return response.data;
    },
    refreshInterval,
    ...restConfig
  } = options;

  const ri = useMemo<
    SWRConfiguration<ResData, Err, BareFetcher<ResData>>['refreshInterval']
  >(() => {
    if (periodic) {
      return 5000;
    }

    return refreshInterval;
  }, [periodic, refreshInterval]);

  const {
    data,
    error,
    // DO NOT get the validating flag directly from the SWR hook. React will
    // re-render every time the validating flag changes, which will cause the
    // component where this hook is used **and** all of its children to
    // re-render!
    mutate,
  } = useSWR<ResData, Err>(url, fetcher, {
    refreshInterval: ri,
    ...restConfig,
  });

  const altData = useMemo<AltResData | undefined>(
    () => mod && data && mod(data),
    [data, mod],
  );

  const loading = useMemo<boolean>(() => !error && !data, [data, error]);

  return {
    altData,
    data,
    error,
    mutate,
    loading,
    // TODO: replace the validating flag with "something", like a context, to
    // minimize the re-render scope when the flag changes.
    validating: false,
  };
};

export default useFetch;
