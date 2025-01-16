import { getData } from './getData';
import { sub } from './sub';

export const getHostData = async () => {
  await sub('get_hosts');

  return getData<AnvilDataHostListHash>('hosts');
};
