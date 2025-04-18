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

  let ri: SWRConfiguration<
    ResData,
    Err,
    BareFetcher<ResData>
  >['refreshInterval'];

  if (periodic) {
    ri = 5000;
  } else {
    ri = refreshInterval;
  }

  const {
    data,
    error,
    isValidating: validating,
    mutate,
  } = useSWR<ResData, Err>(url, fetcher, {
    refreshInterval: ri,
    ...restConfig,
  });

  const altData = useMemo<AltResData | undefined>(
    () => mod && data && mod(data),
    [data, mod],
  );

  const loading = !error && !data;

  return { altData, data, error, mutate, loading, validating };
};

export default useFetch;
