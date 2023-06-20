import express from 'express';

import {
  createServer,
  deleteServer,
  getServer,
  getServerDetail,
} from '../lib/request_handlers/server';

const router = express.Router();

router
  .delete('/', deleteServer)
  .delete('/:serverUuid', deleteServer)
  .get('/', getServer)
  .get('/:serverUUID', getServerDetail)
  .post('/', createServer);

export default router;
