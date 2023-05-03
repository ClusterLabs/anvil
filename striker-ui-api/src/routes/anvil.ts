import express from 'express';

import { getAnvil, getAnvilDetail } from '../lib/request_handlers/anvil';

const router = express.Router();

router.get('/', getAnvil).get('/:anvilUuid', getAnvilDetail);

export default router;
