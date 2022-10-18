import express from 'express';

import {
  createHost,
  getHost,
  getHostConnection,
} from '../lib/request_handlers/host';

const router = express.Router();

router
  .get('/', getHost)
  .get('/connection', getHostConnection)
  .post('/', createHost);

export default router;
