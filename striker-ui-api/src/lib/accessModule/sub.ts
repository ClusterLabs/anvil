import { access } from './instance';

// Un-does `x = 2 ^ n` without logs
const un2n = (value: number): number => {
  let x = value;
  let n = 0;

  while (x > 0) {
    x >>= 1;
    n += 1;
  }

  return n;
};

const quote = (value: string): string => {
  const matches = value.match(/\\*/g);

  if (!matches) {
    return value;
  }

  const result = matches.reduce<string>((previous, before) => {
    const quotes = before.match(/\\/g) ?? [];

    // The number of quotes in each "layer" can be calculated with `2 ^ n - 1`

    // FROM SANDBOX:
    // ivt = (value) => { let x = value; let n = -1; while (x > 0) { x >>= 1; n += 1; } return n; }
    // sample.match(/\\*"/g).reduce((previous, pattern) => previous.replace(new RegExp(`(?<!)${pattern}`, 'g'), '"'.padStart(Math.pow(2, ivt((pattern.match(/\\/g) ?? []).length + 1) + 1) - 1, '\\')), `${sample}`)

    const exponent = un2n(quotes.length + 1);

    const count = Math.pow(2, exponent) - 1;

    const after = '"'.padStart(count, '\\');

    const pattern = new RegExp(`(?<!)${before}`, 'g');

    return previous.replace(pattern, after);
  }, value);

  return `"${result}"`;
};

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
