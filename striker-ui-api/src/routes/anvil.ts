import express from 'express';

import {
  getAnvil,
  getAnvilCpu,
  getAnvilDetail,
} from '../lib/request_handlers/anvil';

const router = express.Router();

router
  .get('/', getAnvil)
  .get('/:anvilUuid/cpu', getAnvilCpu)
  .get('/:anvilUuid', getAnvilDetail);

export default router;
