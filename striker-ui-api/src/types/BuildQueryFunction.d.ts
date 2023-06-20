type QueryResultModifierFunction = (output: unknown) => unknown;

type BuildQueryOptions = {
  afterQueryReturn?: QueryResultModifierFunction;
};

type BuildQueryFunction = (
  request: import('express').Request,
  options?: BuildQueryOptions,
) => string | Promise<string>;
