import { useMemo } from 'react';

import { toProvisionServerResources } from '../../lib/api_converters';
import MessageBox from '../MessageBox';
import ProvisionServerForm from './ProvisionServerForm';
import useFetch from '../../hooks/useFetch';

const useProvisionServerForm = () => {
  const { data: lsos, loading: loadingLsos } =
    useFetch<APIServerOses>('/server/lsos');

  const {
    altData: resources,
    loading: loadingResources,
    validating: validatingResources,
  } = useFetch<APIProvisionServerResources, ProvisionServerResources>(
    '/server/provision',
    {
      mod: toProvisionServerResources,
      refreshInterval: 5000,
    },
  );

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
        resources={resources as ProvisionServerResources}
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
