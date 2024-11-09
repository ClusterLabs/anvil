type BuildQueryHooks = {
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
  hooks: BuildQueryHooks,
) => string | Promise<string>;
