import { useMemo } from 'react';

import MessageBox from '../MessageBox';
import ProvisionServerForm from './ProvisionServerForm';
import useFetch from '../../hooks/useFetch';

const useProvisionServerForm = () => {
  const { data: lsos, loading: loadingLsos } =
    useFetch<APIServerOses>('/server/lsos');

  const {
    data: resources,
    loading: loadingResources,
    validating: validatingResources,
  } = useFetch<APIProvisionServerResources>('/server/provision', {
    refreshInterval: 5000,
  });

  const loading = loadingLsos || loadingResources;

  const validating = validatingResources;

  const form = useMemo<React.ReactNode>(() => {
    if ([lsos, resources].some((value) => !value)) {
      return (
        <MessageBox type="warning">
          Failed to prepare resources for provision server.
        </MessageBox>
      );
    }

    return (
      <ProvisionServerForm
        lsos={lsos as APIServerOses}
        resources={resources as APIProvisionServerResources}
      />
    );
  }, [lsos, resources]);

  return {
    form,
    loading,
    lsos,
    resources,
    validating,
  };
};

export default useProvisionServerForm;
