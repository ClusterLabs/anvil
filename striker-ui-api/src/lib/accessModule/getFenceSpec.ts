import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getFenceSpec = async () => {
  const [, result] = await access.default.interact<[null, AnvilDataFenceHash]>(
    opSub('get_fence_data', {
      pre: ['Striker'],
    }),
    opGetData('fence_data'),
  );

  return result;
};
