import { access } from './instance';

export const sub = async <T extends unknown[]>(
  subroutine: string,
  {
    as = 'default',
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

    return `"${result.replaceAll('"', '\\"')}"`;
  });

  const { sub_results: results } = await access[as].interact<{
    sub_results: T;
  }>('x', chain, ...subParams);

  return results;
};
