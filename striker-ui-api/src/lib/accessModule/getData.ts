import { access } from './instance';
import { poutvar } from '../shell';

export const getData = async <T>(...keys: string[]) => {
  const chain = `data->${keys.join('->')}`;

  const {
    sub_results: [data],
  } = await access.default.interact<{ sub_results: [T] }>('x', chain);

  poutvar(data, `${chain} data: `);

  return data;
};
