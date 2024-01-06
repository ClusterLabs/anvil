export const repeat = (
  value: string,
  count: number,
  { prefix = '' }: { prefix?: string } = {},
): string => {
  const repeated = value.repeat(count);

  return repeated ? `${prefix}${repeated}` : '';
};
