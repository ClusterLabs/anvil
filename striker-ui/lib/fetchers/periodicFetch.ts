import useSWR, { SWRConfiguration } from 'swr';

import fetcher from './fetchJSON';

const periodicFetch = <T>(
  url: string,
  { refreshInterval = 5000, onSuccess }: SWRConfiguration<T> = {},
): GetResponses<T> => {
  // The purpose of react-hooks/rules-of-hooks is to ensure that react hooks
  // are called in order (i.e., not potentially skipped due to conditionals).
  // We can safely disable this rule as this function is simply a wrapper.
  // eslint-disable-next-line react-hooks/rules-of-hooks
  const { data, error: swrError } = useSWR<T>(url, fetcher, {
    refreshInterval,
    onSuccess,
  });

  return {
    data,
    isLoading: !swrError && !data,
    error: swrError,
  };
};

export default periodicFetch;
