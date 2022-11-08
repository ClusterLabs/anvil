export const match = (
  value: string,
  regexp: string | RegExp,
  { fallbackResult = [] }: { fallbackResult?: string[] } = {},
) => value.match(regexp) ?? fallbackResult;
