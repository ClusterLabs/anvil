import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getHostData = async (): Promise<AnvilDataHostListHash> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataHostListHash]>]
  >(opSub('get_hosts'), opGetData('hosts'));

  return result;
};
