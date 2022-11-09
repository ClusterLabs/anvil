import express from 'express';

import {
  poweroffHost,
  rebootHost,
  updateSystem,
} from '../lib/request_handlers/command';

const router = express.Router();

router
  .put('/poweroff-host', poweroffHost)
  .put('/reboot-host', rebootHost)
  .put('/update-system', updateSystem);

export default router;
