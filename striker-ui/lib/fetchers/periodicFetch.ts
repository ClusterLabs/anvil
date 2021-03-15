import useSWR from 'swr';
import fetcher from './fetchJSON';

const PeriodicFetch = <T>(
  url: string,
  uuid: string,
  refreshInterval = 2000,
): GetResponses => {
  const { data, error } = useSWR<T>(`${url}${uuid}`, fetcher, {
    refreshInterval,
  });
  return {
    data,
    isLoading: !error && !data,
    isError: error,
  };
};

export default PeriodicFetch;
