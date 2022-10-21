type QueryResultModifierFunction = (result: unknown) => unknown;

type BuildQueryOptions = {
  afterQueryReturn?: QueryResultModifierFunction;
};

type BuildQueryFunction = (
  request: import('express').Request,
  options?: BuildQueryOptions,
) => string;
