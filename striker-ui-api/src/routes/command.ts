import express from 'express';

import { poweroffHost, rebootHost } from '../lib/request_handlers/command';

const router = express.Router();

router.put('/poweroff-host', poweroffHost).put('/reboot-host', rebootHost);

export default router;
