import { FC } from 'react';

import PrepareHostNetworkForm from './PrepareHostNetworkForm';
import Spinner from '../Spinner';
import useFetch from '../../hooks/useFetch';

const PrepareHostNetwork: FC<PrepareHostNetworkProps> = (props) => {
  const { uuid } = props;

  const { data: detail } = useFetch<APIHostDetail>(`/host/${uuid}`);

  if (!detail) {
    return <Spinner mt={0} />;
  }

  return <PrepareHostNetworkForm detail={detail} uuid={uuid} />;
};

export default PrepareHostNetwork;
