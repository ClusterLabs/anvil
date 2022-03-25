import express from 'express';

import getServer from '../lib/request_handlers/server/getServer';

const router = express.Router();

router.get('/', getServer);

export default router;
