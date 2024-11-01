import { RequestHandler } from 'express';

import { query } from '../accessModule';
import call from '../call';
import { Responder } from '../Responder';
import { pout, poutvar } from '../shell';

const buildGetRequestHandler =
  <
    P = Express.RhParamsDictionary,
    ResBody = Express.RhResBody,
    ReqBody = Express.RhReqBody,
    ReqQuery = Express.RhReqQuery,
    Locals extends Express.RhLocals = Express.RhLocals,
  >(
    scriptOrCallback:
      | string
      | BuildQueryFunction<P, ResBody, ReqBody, ReqQuery, Locals>,
    { beforeRespond }: BuildGetRequestHandlerOptions = {},
  ): RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals> =>
  async (request, response) => {
    const respond = new Responder<ResBody, Locals>(response);

    pout('Calling CLI script to get data.');

    const buildQueryOptions: BuildQueryOptions = {};

    let result: unknown;

    try {
      const sqlscript: string =
        typeof scriptOrCallback === 'function'
          ? await scriptOrCallback(request, buildQueryOptions)
          : scriptOrCallback;

      result = await query(sqlscript);
    } catch (error) {
      // Don't return, let the hooks handle fallback
      respond.s500('d7348a0', `Failed to execute query; CAUSE: ${error}`);
    }

    poutvar(result, `Query stdout pre-hooks (type=[${typeof result}]): `);

    const { afterQueryReturn } = buildQueryOptions;

    let responseBody = call<ResBody>(afterQueryReturn, {
      parameters: [result],
      notCallableReturn: result,
    });

    responseBody = call<ResBody>(beforeRespond, {
      parameters: [responseBody],
      notCallableReturn: responseBody,
    });

    poutvar(result, `Query stdout post-hooks (type=[${typeof result}]): `);

    return respond.s200(responseBody);
  };

export default buildGetRequestHandler;
