import express from 'express';

import {
  getAnvil,
  getAnvilCpu,
  getAnvilSummary,
  getAnvilDetail,
  getAnvilMemory,
  getAnvilNetwork,
  getAnvilStore,
} from '../lib/request_handlers/anvil';

const router = express.Router();

router
  .get('/', getAnvil)
  .get('/summary', getAnvilSummary)
  .get('/:anvilUuid/cpu', getAnvilCpu)
  .get('/:anvilUuid/memory', getAnvilMemory)
  .get('/:anvilUuid/network', getAnvilNetwork)
  .get('/:anvilUuid/store', getAnvilStore)
  .get('/:anvilUuid', getAnvilDetail);

export default router;
