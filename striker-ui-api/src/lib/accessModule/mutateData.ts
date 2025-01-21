import { access } from './instance';

export const opMutateData = (args: {
  keys: string[];
  operator: string;
  value: string;
}) => {
  const { keys, operator, value } = args;

  const chain = `data->${keys.join('->')}`;

  return `x ${chain} ${operator} ${value}`;
};

export const mutateData = async <T>(
  ...params: Parameters<typeof opMutateData>
): Promise<T> => {
  const [
    {
      sub_results: [data],
    },
  ] = await access.default.interact<
    [
      {
        sub_results: [T];
      },
    ]
  >(opMutateData(...params));

  return data;
};
