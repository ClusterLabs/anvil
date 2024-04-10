import { Request, Response } from 'express';

import { query } from '../accessModule';
import call from '../call';
import { perr, pout, poutvar } from '../shell';

const buildGetRequestHandler =
  (
    scriptOrCallback: string | BuildQueryFunction,
    { beforeRespond }: BuildGetRequestHandlerOptions = {},
  ) =>
  async (request: Request, response: Response) => {
    pout('Calling CLI script to get data.');

    const buildQueryOptions: BuildQueryOptions = {};

    let result: unknown;

    try {
      const sqlscript: string =
        typeof scriptOrCallback === 'function'
          ? await scriptOrCallback(request, buildQueryOptions)
          : scriptOrCallback;

      result = await query(sqlscript);
    } catch (queryError) {
      perr(`Failed to execute query; CAUSE: ${queryError}`);

      return response.status(500).send();
    }

    poutvar(result, `Query stdout pre-hooks (type=[${typeof result}]): `);

    const { afterQueryReturn } = buildQueryOptions;

    result = call(afterQueryReturn, {
      parameters: [result],
      notCallableReturn: result,
    });

    result = call(beforeRespond, {
      parameters: [result],
      notCallableReturn: result,
    });

    poutvar(result, `Query stdout post-hooks (type=[${typeof result}]): `);

    response.json(result);
  };

export default buildGetRequestHandler;
