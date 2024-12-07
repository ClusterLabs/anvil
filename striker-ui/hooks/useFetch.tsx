import { useMemo } from 'react';
import useSWR, { BareFetcher, KeyedMutator, SWRConfiguration } from 'swr';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import fetchJSON from '../lib/fetchers/fetchJSON';

type FetchHookResponse<D, E extends Error = Error> = {
  data?: D;
  error?: E;
  mutate: KeyedMutator<D>;
  loading: boolean;
  validating: boolean;
};

const useFetch = <Data, Alt = Data>(
  url: string,
  options: SWRConfiguration<Data> & {
    baseUrl?: string;
    fetcher?: BareFetcher<Data>;
    mod?: (data: Data) => Alt;
  } = {},
): FetchHookResponse<Data> & { altData?: Alt } => {
  const {
    baseUrl = API_BASE_URL,
    fetcher = fetchJSON,
    mod,
    ...config
  } = options;

  const {
    data,
    error,
    isValidating: validating,
    mutate,
  } = useSWR<Data>(`${baseUrl}${url}`, fetcher, config);

  const altData = useMemo<Alt | undefined>(
    () => mod && data && mod(data),
    [data, mod],
  );

  const loading = !error && !data;

  return { altData, data, error, mutate, loading, validating };
};

export default useFetch;
