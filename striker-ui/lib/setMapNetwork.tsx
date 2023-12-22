import api from './api';
import handleAPIError from './handleAPIError';

const setMapNetwork = (
  value: 0 | 1,
  handleError?: (msg: Message) => void,
): void => {
  api.put('/init/set-map-network', { value }).catch((error) => {
    const emsg = handleAPIError(error);

    emsg.children = (
      <>
        Failed to {value ? 'enable' : 'disable'} network mapping.{' '}
        {emsg.children}
      </>
    );

    handleError?.call(null, emsg);
  });
};

export default setMapNetwork;
