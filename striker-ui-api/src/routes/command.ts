import express from 'express';

import {
  getHostSSH,
  poweroffHost,
  rebootHost,
  runManifest,
  updateSystem,
} from '../lib/request_handlers/command';

const router = express.Router();

router
  .put('/inquire-host', getHostSSH)
  .put('/poweroff-host', poweroffHost)
  .put('/reboot-host', rebootHost)
  .put('/run-manifest/:manifestUuid', runManifest)
  .put('/update-system', updateSystem);

export default router;
