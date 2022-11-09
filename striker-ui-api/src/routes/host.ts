import express from 'express';

import {
  createHost,
  getHost,
  getHostConnection,
  getHostDetail,
  updateHost,
} from '../lib/request_handlers/host';

const router = express.Router();

router
  .get('/', getHost)
  .get('/connection', getHostConnection)
  .get('/:hostUUID', getHostDetail)
  .post('/', createHost)
  .put('/:hostUUID', updateHost);

export default router;
