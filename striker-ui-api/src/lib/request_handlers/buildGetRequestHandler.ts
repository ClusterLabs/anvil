import { Request, Response } from 'express';

import { query } from '../accessModule';
import call from '../call';
import { stderr, stdout, stdoutVar } from '../shell';

const buildGetRequestHandler =
  (
    scriptOrCallback: string | BuildQueryFunction,
    { beforeRespond }: BuildGetRequestHandlerOptions = {},
  ) =>
  async (request: Request, response: Response) => {
    stdout('Calling CLI script to get data.');

    const buildQueryOptions: BuildQueryOptions = {};

    let result: unknown;

    try {
      const sqlscript: string =
        typeof scriptOrCallback === 'function'
          ? await scriptOrCallback(request, buildQueryOptions)
          : scriptOrCallback;

      result = await query(sqlscript);
    } catch (queryError) {
      stderr(`Failed to execute query; CAUSE: ${queryError}`);

      return response.status(500).send();
    }

    stdoutVar(result, `Query stdout pre-hooks (type=[${typeof result}]): `);

    const { afterQueryReturn } = buildQueryOptions;

    result = call(afterQueryReturn, {
      parameters: [result],
      notCallableReturn: result,
    });

    result = call(beforeRespond, {
      parameters: [result],
      notCallableReturn: result,
    });

    stdoutVar(result, `Query stdout post-hooks (type=[${typeof result}]): `);

    response.json(result);
  };

export default buildGetRequestHandler;
