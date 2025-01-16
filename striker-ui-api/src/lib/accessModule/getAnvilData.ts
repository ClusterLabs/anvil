import { getData } from './getData';
import { sub } from './sub';

export const getAnvilData = async () => {
  await sub('get_anvils');

  return getData<AnvilDataAnvilListHash>('anvils');
};
