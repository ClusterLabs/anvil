import express from 'express';

import { getFence, getFenceTemplate } from '../lib/request_handlers/fence';

const router = express.Router();

router.get('/', getFence).get('/template', getFenceTemplate);

export default router;
