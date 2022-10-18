import express from 'express';

import { initializeStriker } from '../lib/request_handlers';
import { poweroffHost, rebootHost } from '../lib/request_handlers/command';

const router = express.Router();

router
  .put('/initialize-striker', initializeStriker)
  .put('/poweroff-host', poweroffHost)
  .put('/reboot-host', rebootHost);

export default router;
