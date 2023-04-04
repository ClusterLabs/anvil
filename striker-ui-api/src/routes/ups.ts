import express from 'express';

import { getUPS, getUPSTemplate } from '../lib/request_handlers/ups';

const router = express.Router();

router.get('/', getUPS).get('/template', getUPSTemplate);

export default router;
