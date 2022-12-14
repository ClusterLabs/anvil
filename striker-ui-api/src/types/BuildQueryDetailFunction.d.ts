type BuildQueryDetailOptions = { keys?: string[] | '*' };

type BuildQueryDetailReturn = {
  query: string;
} & Pick<BuildQueryOptions, 'afterQueryReturn'>;

type BuildQueryDetailFunction = (
  options?: BuildQueryDetailOptions,
) => BuildQueryDetailReturn;
