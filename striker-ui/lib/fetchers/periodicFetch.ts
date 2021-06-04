import useSWR from 'swr';
import fetcher from './fetchJSON';

const PeriodicFetch = <T>(
  url: string,
  refreshInterval = 5000,
): GetResponses => {
  const { data, error } = useSWR<T>(url, fetcher, {
    refreshInterval,
  });
  return {
    data,
    isLoading: !error && !data,
    isError: error,
  };
};

export default PeriodicFetch;
