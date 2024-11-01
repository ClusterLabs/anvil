type BuildQueryOptions = {
  afterQueryReturn?: QueryResultModifierFunction;
};

type BuildQueryFunction<
  P,
  ResBody,
  ReqBody,
  ReqQuery,
  Locals extends Express.RhLocals,
> = (
  request: import('express').Request<P, ResBody, ReqBody, ReqQuery, Locals>,
  options?: BuildQueryOptions,
) => string | Promise<string>;
