import { AssertionError } from 'assert';
import { RequestHandler } from 'express';

import { buildManifest } from './buildManifest';
import { perr } from '../../shell';

export const createManifest: RequestHandler = async (...handlerArgs) => {
  const [, response] = handlerArgs;

  let result: Record<string, string> = {};

  try {
    result = await buildManifest(...handlerArgs);
  } catch (error) {
    perr(`Failed to create new install manifest; CAUSE ${error}`);

    let code = 500;

    if (error instanceof AssertionError) {
      code = 400;
    }

    response.status(code).send();

    return;
  }

  response.status(201).send(result);
};
