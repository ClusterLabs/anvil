import express from 'express';

import {
  getHostSSH,
  poweroffStriker,
  rebootStriker,
  runManifest,
  startAn,
  startSubnode,
  stopAn,
  stopSubnode,
  updateSystem,
} from '../lib/request_handlers/command';

const router = express.Router();

router
  .put('/inquire-host', getHostSSH)
  .put('/poweroff-host', poweroffStriker)
  .put('/reboot-host', rebootStriker)
  .put('/run-manifest/:manifestUuid', runManifest)
  .put('/start-an/:uuid', startAn)
  .put('/start-subnode/:uuid', startSubnode)
  .put('/stop-an/:uuid', stopAn)
  .put('/stop-subnode/:uuid', stopSubnode)
  .put('/update-system', updateSystem);

export default router;
