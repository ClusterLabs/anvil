import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  getHostSSH,
  joinAn,
  leaveAn,
  poweroffStriker,
  rebootStriker,
  runManifest,
  scanNetwork,
  startAn,
  startServer,
  startSubnode,
  stopAn,
  stopServer,
  stopSubnode,
  updateSystem,
} from '../lib/request_handlers/command';

const router = express.Router();

router
  .put('/inquire-host', getHostSSH)
  .put('/join-an/:uuid', joinAn)
  .put('/leave-an/:uuid', leaveAn)
  .put('/poweroff-host', poweroffStriker)
  .put('/reboot-host', rebootStriker)
  .put('/run-manifest/:uuid', validateRequestTarget(), runManifest)
  .put('/scan-network', scanNetwork)
  .put('/start-an/:uuid', startAn)
  .put('/start-server/:uuid', startServer)
  .put('/start-subnode/:uuid', startSubnode)
  .put('/stop-an/:uuid', stopAn)
  .put('/stop-server/:uuid', stopServer)
  .put('/stop-subnode/:uuid', stopSubnode)
  .put('/update-system', updateSystem);

export default router;
