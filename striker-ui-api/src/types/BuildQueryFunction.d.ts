type BuildQueryOptions = {
  afterQueryReturn?: (queryStdout: unknown) => unknown;
};

type BuildQueryFunction = (
  request: import('express').Request,
  options?: BuildQueryOptions,
) => string;
