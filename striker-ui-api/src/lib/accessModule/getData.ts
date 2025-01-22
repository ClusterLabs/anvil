import { access } from './instance';

export const opGetData = (...keys: string[]) => {
  const chain = `data->${keys.join('->')}`;

  return `x ${chain}`;
};

export const getData = async <T>(
  ...params: Parameters<typeof opGetData>
): Promise<T> => {
  const [
    {
      sub_results: [data],
    },
  ] = await access.default.interact<[SubroutineOutputWrapper<[T]>]>(
    opGetData(...params),
  );

  return data;
};
