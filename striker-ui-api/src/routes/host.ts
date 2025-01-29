import express from 'express';

import {
  createHost,
  createHostConnection,
  deleteHostConnection,
  getHost,
  getHostConnection,
  getHostDetail,
  getHostNicModels,
  prepareHost,
  updateHost,
} from '../lib/request_handlers/host';

const CONNECTION_PATH = '/connection';

const router = express.Router();

router
  .get('/', getHost)
  .get(CONNECTION_PATH, getHostConnection)
  .get('/:uuid/nic-model', getHostNicModels)
  .get('/:hostUUID', getHostDetail)
  .post('/', createHost)
  .post(CONNECTION_PATH, createHostConnection)
  .put('/prepare', prepareHost)
  .put('/:hostUUID?', updateHost)
  .delete(CONNECTION_PATH, deleteHostConnection);

export default router;
