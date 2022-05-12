import express from 'express';

import { createServer, getServer } from '../lib/request_handlers/server';

const router = express.Router();

router.get('/', getServer).post('/', createServer);

export default router;
