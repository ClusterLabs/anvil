import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getAnvilData = async () => {
  const [, result] = await access.default.interact<
    [null, AnvilDataAnvilListHash]
  >(opSub('get_anvils'), opGetData('anvils'));

  return result;
};
