import { RequestHandler } from 'express';

import { configStriker } from './configStriker';
import { sanitizeQS } from '../../sanitizeQS';
import { stdout } from '../../shell';

// Ensure each create handler sends a response at the end of any branch.
const MAP_TO_CREATE_HANDLER: Record<string, RequestHandler | undefined> = {
  striker: configStriker,
};

export const createHost: RequestHandler = (...args) => {
  const [
    {
      query: { hostType: rawHostType },
    },
  ] = args;

  const hostType = sanitizeQS(rawHostType, { returnType: 'string' });

  stdout(`hostType=[${hostType}]`);

  MAP_TO_CREATE_HANDLER[hostType]?.call(null, ...args);
};