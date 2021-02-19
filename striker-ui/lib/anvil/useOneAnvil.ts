import useSWR from 'swr';

import fetchJSON from '../fetchers/fetchJSON';

const useOneAnvil = (
  anvilUUID: string,
  refreshInterval = 2000,
): GetOneAnvilResponse => {
  const {
    data = { nodes: [], timestamp: 0 },
    error = null,
  } = useSWR<AnvilStatus>(`/api/anvils/${anvilUUID}`, fetchJSON, {
    refreshInterval,
  });

  return {
    anvilStatus: data,
    error,
    isLoading: !error && !data,
  };
};

export default useOneAnvil;
