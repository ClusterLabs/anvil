import useSWR from 'swr';
import fetcher from './fetchJSON';

const PeriodicFetch = <T>(
  uuid: string,
  uri: string,
  refreshInterval = 2000,
): GetResponses => {
  const { data, error } = useSWR<T>(`${uri}${uuid}`, fetcher, {
    refreshInterval,
  });

  return {
    data,
    isLoading: !error && !data,
    isError: error,
  };
};

export default PeriodicFetch;
