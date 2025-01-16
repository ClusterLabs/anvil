import { getData } from './getData';
import { sub } from './sub';

export const getFenceSpec = async () => {
  await sub('get_fence_data', { pre: ['Striker'] });

  return getData<AnvilDataFenceHash>('fence_data');
};
