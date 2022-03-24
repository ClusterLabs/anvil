import { Request, Response } from 'express';

import { dbQuery } from '../accessDB';

const buildGetRequestHandler =
  (query: string | ((request: Request) => string)) =>
  (request: Request, response: Response) => {
    console.log('Calling CLI script to get data.');

    let queryStdout;

    try {
      ({ stdout: queryStdout } = dbQuery(
        typeof query === 'function' ? query(request) : query,
      ));
    } catch (queryError) {
      console.log(`Query error: ${queryError}`);

      response.status(500).send();
    }

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
