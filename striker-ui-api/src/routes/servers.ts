import express from 'express';

import getServers from '../lib/request_handlers/servers/getServers';

const router = express.Router();

router.get('/', getServers);

export default router;
