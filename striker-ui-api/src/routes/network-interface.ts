import express from 'express';

import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router.get('/', getNetworkInterface).get('/:host', getNetworkInterface);

export default router;
