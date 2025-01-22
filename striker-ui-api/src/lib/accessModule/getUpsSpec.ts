import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getUpsSpec = async (): Promise<AnvilDataUPSHash> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataUPSHash]>]
  >(
    opSub('get_ups_data', {
      pre: ['Striker'],
    }),
    opGetData('ups_data'),
  );

  return result;
};
