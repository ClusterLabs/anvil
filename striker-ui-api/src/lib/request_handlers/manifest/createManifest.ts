import { AssertionError } from 'assert';
import { RequestHandler } from 'express';

import { buildManifest } from './buildManifest';
import { stderr } from '../../shell';

export const createManifest: RequestHandler = (...handlerArgs) => {
  const [, response] = handlerArgs;

  let result: Record<string, string> = {};

  try {
    result = buildManifest(...handlerArgs);
  } catch (buildError) {
    stderr(`Failed to create new install manifest; CAUSE ${buildError}`);

    let code = 500;

    if (buildError instanceof AssertionError) {
      code = 400;
    }

    response.status(code).send();

    return;
  }

  response.status(201).send(result);
};
