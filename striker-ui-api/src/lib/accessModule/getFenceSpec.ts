import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getFenceSpec = async (): Promise<AnvilDataFenceHash> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataFenceHash]>]
  >(
    opSub('get_fence_data', {
      pre: ['Striker'],
    }),
    opGetData('fence_data'),
  );

  return result;
};
