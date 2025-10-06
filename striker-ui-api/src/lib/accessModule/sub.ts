import { access } from './instance';
import { quote } from '../quote';

export const opSub = (
  subroutine: string,
  {
    params = [],
    pre = ['Database'],
  }: {
    as?: keyof typeof access;
    params?: unknown[];
    pre?: string[];
  } = {},
) => {
  const chain = `${pre.join('->')}->${subroutine}`;

  const subParams: string[] = params.map<string>((p) => {
    let result: string;

    try {
      result = JSON.stringify(p);
    } catch (error) {
      result = String(p);
    }

    return quote(result);
  });

  return `x ${chain} ${subParams.join(' ')}`;
};

export const sub = async <T extends unknown[]>(
  ...params: Parameters<typeof opSub>
) => {
  const [, { as = 'default' } = {}] = params;

  const [{ sub_results: results }] = await access[as].interact<
    [SubroutineOutputWrapper<T>]
  >(opSub(...params));

  return results;
};
