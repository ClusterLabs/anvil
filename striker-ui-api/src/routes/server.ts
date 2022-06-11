import express from 'express';

import {
  createServer,
  getServer,
  getServerDetail,
} from '../lib/request_handlers/server';

const router = express.Router();

router
  .get('/', getServer)
  .get('/:serverUUID', getServerDetail)
  .post('/', createServer);

export default router;
