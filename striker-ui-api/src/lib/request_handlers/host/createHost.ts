import { RequestHandler } from 'express';

import { buildBranchRequestHandler } from '../buildBranchRequestHandler';
import { configStriker } from './configStriker';

export const createHost: RequestHandler = buildBranchRequestHandler({
  striker: configStriker,
});
