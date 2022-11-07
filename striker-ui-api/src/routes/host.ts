import express from 'express';

import {
  createHost,
  getHost,
  getHostConnection,
  getHostDetail,
} from '../lib/request_handlers/host';

const router = express.Router();

router
  .get('/', getHost)
  .get('/connection', getHostConnection)
  .get('/:hostUUID', getHostDetail)
  .post('/', createHost);

export default router;
