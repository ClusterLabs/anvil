import { RequestHandler } from 'express';

import { buildBranchRequestHandler } from '../buildBranchRequestHandler';
import { setHostInstallTarget } from './setHostInstallTarget';

export const updateHost: RequestHandler = buildBranchRequestHandler({
  'install-target': setHostInstallTarget,
});
