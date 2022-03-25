import { Request, Response } from 'express';

import { dbQuery } from '../accessDB';
import call from '../call';

const buildGetRequestHandler =
  (
    query: string | BuildQueryFunction,
    { beforeRespond }: BuildGetRequestHandlerOptions = {},
  ) =>
  (request: Request, response: Response) => {
    console.log('Calling CLI script to get data.');

    const buildQueryOptions: BuildQueryOptions = {};

    let queryStdout;

    try {
      ({ stdout: queryStdout } = dbQuery(
        call<string>(query, {
          parameters: [request, buildQueryOptions],
          notCallableReturn: query,
        }),
      ));
    } catch (queryError) {
      console.log(`Query error: ${queryError}`);

      response.status(500).send();
    }

    const { afterQueryReturn } = buildQueryOptions;

    queryStdout = call(afterQueryReturn, {
      parameters: [queryStdout],
      notCallableReturn: queryStdout,
    });

    queryStdout = call(beforeRespond, {
      parameters: [queryStdout],
      notCallableReturn: queryStdout,
    });

    console.log(
      `Query stdout (type=[${typeof queryStdout}]): ${JSON.stringify(
        queryStdout,
        null,
        2,
      )}`,
    );

    response.json(queryStdout);
  };

export default buildGetRequestHandler;
