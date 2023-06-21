import { RequestHandler } from 'express';

import { buildBranchRequestHandler } from '../buildBranchRequestHandler';
import { configStriker } from './configStriker';
import { setHostInstallTarget } from './setHostInstallTarget';

export const updateHost: RequestHandler = buildBranchRequestHandler({
  'install-target': setHostInstallTarget as RequestHandler,
  striker: configStriker,
});
