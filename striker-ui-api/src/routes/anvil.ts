import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  getAnvil,
  getAnvilCpu,
  getAnvilSummary,
  getAnvilDetail,
  getAnvilMemory,
  getAnvilNetwork,
  getAnvilStorage,
} from '../lib/request_handlers/anvil';

const single = express.Router();

single.get('/storage', getAnvilStorage);

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
