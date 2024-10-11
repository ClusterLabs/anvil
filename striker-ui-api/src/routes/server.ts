import express from 'express';

import {
  createServer,
  deleteServer,
  getServer,
  getServerDetail,
  renameServer,
} from '../lib/request_handlers/server';

const router = express.Router();

router
  .delete('/', deleteServer)
  .delete('/:serverUuid', deleteServer)
  .get('/', getServer)
  .get('/:serverUUID', getServerDetail)
  .post('/', createServer)
  .put('/:uuid/rename', renameServer);

export default router;
