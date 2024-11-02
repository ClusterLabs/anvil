type BuildQueryDetailOptions = { keys?: string[] | '*' };

type BuildQueryDetailReturn = {
  query: string;
} & Pick<BuildQueryHooks, 'afterQueryReturn'>;

type BuildQueryDetailFunction = (
  options?: BuildQueryDetailOptions,
) => BuildQueryDetailReturn;
