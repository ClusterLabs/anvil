import { RequestHandler } from 'express';

import { sanitize } from '../sanitize';
import { stderr, stdout } from '../shell';

export const buildBranchRequestHandler: (map: {
  [handler: string]: RequestHandler | undefined;
}) => RequestHandler =
  (map) =>
  (...args) => {
    const [
      {
        query: { handler: rawHandler },
      },
      response,
    ] = args;

    const handlerKey = sanitize(rawHandler, 'string');

    stdout(`Create host handler: ${handlerKey}`);

    // Ensure each handler sends a response at the end of any branch.
    const handler = map[handlerKey];

    if (handler) {
      handler(...args);
    } else {
      stderr(`Handler is not registered; got [${handlerKey}]`);

      response.status(400).send();

      return;
    }
  };
