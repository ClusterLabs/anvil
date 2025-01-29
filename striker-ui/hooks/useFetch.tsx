import { useMemo } from 'react';
import useSWR, { BareFetcher, KeyedMutator, SWRConfiguration } from 'swr';

import api from '../lib/api';

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
    fetcher?: BareFetcher<Data>;
    mod?: (data: Data) => Alt;
    periodic?: boolean;
    timeout?: number;
  } = {},
): FetchHookResponse<Data> & { altData?: Alt } => {
  const {
    timeout = 5000,
    mod,
    periodic,
    // Depends on the above
    fetcher = async (l) => {
      const response = await api.get(l, { timeout });

      return response.data;
    },
    ...config
  } = options;

  let refreshInterval: number | undefined;

  if (periodic) {
    refreshInterval = 5000;
  }

  const {
    data,
    error,
    isValidating: validating,
    mutate,
  } = useSWR<Data>(url, fetcher, {
    refreshInterval,
    ...config,
  });

  const altData = useMemo<Alt | undefined>(
    () => mod && data && mod(data),
    [data, mod],
  );

  const loading = !error && !data;

  return { altData, data, error, mutate, loading, validating };
};

export default useFetch;
