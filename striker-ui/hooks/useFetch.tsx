import useSWR, { BareFetcher, SWRConfiguration } from 'swr';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import fetchJSON from '../lib/fetchers/fetchJSON';

type FetchHookResponse<D, E extends Error = Error> = {
  data?: D;
  error?: E;
  loading: boolean;
};

const useFetch = <Data,>(
  url: string,
  options: SWRConfiguration<Data> & {
    fetcher?: BareFetcher<Data>;
    baseUrl?: string;
  } = {},
): FetchHookResponse<Data> => {
  const { fetcher = fetchJSON, baseUrl = API_BASE_URL, ...config } = options;

  const { data, error } = useSWR<Data>(`${baseUrl}${url}`, fetcher, config);

  const loading = !error && !data;

  return { data, error, loading };
};

export default useFetch;
