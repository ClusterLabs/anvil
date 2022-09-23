import express from 'express';

import { getHost, getHostConnection } from '../lib/request_handlers/host';

const router = express.Router();

router.get('/', getHost).get('/connection', getHostConnection);

export default router;
