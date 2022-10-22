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
  .get('/:hostUUID', getHostDetail)
  .get('/connection', getHostConnection)
  .post('/', createHost);

export default router;
