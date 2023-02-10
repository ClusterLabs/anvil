const getQueryParam = (
  queryParam?: string | string[],
  {
    fallbackValue = '',
    joinSeparator = '',
    limit = 1,
  }: { fallbackValue?: string; joinSeparator?: string; limit?: number } = {},
): string =>
  queryParam instanceof Array
    ? queryParam.slice(0, limit).join(joinSeparator)
    : queryParam ?? fallbackValue;

export default getQueryParam;
