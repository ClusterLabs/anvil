import { RequestHandler } from 'express';

import { buildBranchRequestHandler } from '../buildBranchRequestHandler';
import { configStriker } from './configStriker';
import { prepareNetwork } from './prepareNetwork';
import { setHostInstallTarget } from './setHostInstallTarget';

export const updateHost: RequestHandler = buildBranchRequestHandler({
  'install-target': setHostInstallTarget as RequestHandler,
  'subnode-network': prepareNetwork as RequestHandler,
  striker: configStriker,
});
