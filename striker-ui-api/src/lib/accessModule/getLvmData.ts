import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getLvmData = async () => {
  const [, result] = await access.default.interact<[null, AnvilDataLvm]>(
    opSub('get_lvm_data'),
    opGetData('lvm'),
  );

  return result;
};
