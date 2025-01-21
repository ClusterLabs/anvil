import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getAnvilData = async (): Promise<AnvilDataAnvilListHash> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataAnvilListHash]>]
  >(opSub('get_anvils'), opGetData('anvils'));

  return result;
};
