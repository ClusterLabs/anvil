import express from 'express';

import { getJob, getJobDetail } from '../lib/request_handlers/job';

const router = express.Router();

router.get('/', getJob).get('/:uuid', getJobDetail);

export default router;
