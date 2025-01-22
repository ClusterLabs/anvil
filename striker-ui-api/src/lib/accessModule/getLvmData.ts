import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getLvmData = async (): Promise<AnvilDataLvm> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataLvm]>]
  >(opSub('get_lvm_data'), opGetData('lvm'));

  return result;
};
