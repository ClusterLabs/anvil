import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getHostData = async () => {
  const [, result] = await access.default.interact<
    [null, AnvilDataHostListHash]
  >(opSub('get_hosts'), opGetData('hosts'));

  return result;
};
