import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getUpsSpec = async () => {
  const [, result] = await access.default.interact<[null, AnvilDataUPSHash]>(
    opSub('get_ups_data', {
      pre: ['Striker'],
    }),
    opGetData('ups_data'),
  );

  return result;
};
