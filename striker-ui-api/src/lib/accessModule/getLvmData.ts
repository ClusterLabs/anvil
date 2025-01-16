import { getData } from './getData';
import { sub } from './sub';

export const getLvmData = async () => {
  await sub('get_lvm_data');

  return getData<AnvilDataLvm>('lvm');
};
