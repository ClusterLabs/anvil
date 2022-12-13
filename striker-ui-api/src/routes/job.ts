import express from 'express';

import { getJob } from '../lib/request_handlers/job';

const router = express.Router();

router.get('/', getJob);

export default router;
