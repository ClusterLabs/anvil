import { getData } from './getData';
import { sub } from './sub';

export const getUpsSpec = async () => {
  await sub('get_ups_data', { pre: ['Striker'] });

  return getData<AnvilDataUPSHash>('ups_data');
};
