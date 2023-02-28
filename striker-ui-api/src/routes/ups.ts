import express from 'express';

import { getUPSTemplate } from '../lib/request_handlers/ups';

const router = express.Router();

router.get('/template', getUPSTemplate);

export default router;
