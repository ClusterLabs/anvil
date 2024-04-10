import { AssertionError } from 'assert';
import { RequestHandler } from 'express';

import { buildManifest } from './buildManifest';
import { perr } from '../../shell';

export const updateManifest: RequestHandler = async (...args) => {
  const [request, response] = args;
  const {
    params: { manifestUuid },
  } = request;

  let result: Record<string, string> = {};

  try {
    result = await buildManifest(...args);
  } catch (error) {
    perr(`Failed to update install manifest ${manifestUuid}; CAUSE: ${error}`);

    let code = 500;

    if (error instanceof AssertionError) {
      code = 400;
    }

    response.status(code).send();

    return;
  }

  response.status(200).send(result);
};
