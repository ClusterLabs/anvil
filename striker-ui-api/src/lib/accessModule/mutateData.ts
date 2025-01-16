import { access } from './instance';
import { poutvar } from '../shell';

export const mutateData = async <T>(args: {
  keys: string[];
  operator: string;
  value: string;
}): Promise<T> => {
  const { keys, operator, value } = args;

  const chain = `data->${keys.join('->')}`;

  const {
    sub_results: [data],
  } = await access.default.interact<{ sub_results: [T] }>(
    'x',
    chain,
    operator,
    value,
  );

  poutvar(data, `${chain} data: `);

  return data;
};
