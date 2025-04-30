import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  createAnvilStorageGroup,
  deleteAnvilStorageGroup,
  getAnvil,
  getAnvilCpu,
  getAnvilSummary,
  getAnvilDetail,
  getAnvilMemory,
  getAnvilNetwork,
  getAnvilStorage,
  updateAnvilStorageGroup,
} from '../lib/request_handlers/anvil';

const single = express.Router();

single
  .route('/storage')
  .delete(deleteAnvilStorageGroup)
  .get(getAnvilStorage)
  .post(createAnvilStorageGroup)
  .put(updateAnvilStorageGroup);

const router = express.Router();

router
  .get('/', getAnvil)
  .get('/summary', getAnvilSummary)
  .get('/:anvilUuid/cpu', getAnvilCpu)
  .get('/:anvilUuid/memory', getAnvilMemory)
  .get('/:anvilUuid/network', getAnvilNetwork)
  .get('/:anvilUuid', getAnvilDetail);

router.use('/:uuid', validateRequestTarget(), single);

export default router;
