import { AssertionError } from 'assert';
import { RequestHandler } from 'express';

import { buildManifest } from './buildManifest';
import { stderr } from '../../shell';

export const updateManifest: RequestHandler = (...args) => {
  const [request, response] = args;
  const {
    params: { manifestUuid },
  } = request;

  let result: Record<string, string> = {};

  try {
    result = buildManifest(...args);
  } catch (buildError) {
    stderr(
      `Failed to update install manifest ${manifestUuid}; CAUSE: ${buildError}`,
    );

    let code = 500;

    if (buildError instanceof AssertionError) {
      code = 400;
    }

    response.status(code).send();

    return;
  }

  response.status(200).send(result);
};
