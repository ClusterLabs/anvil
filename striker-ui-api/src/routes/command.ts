import express from 'express';

import { initializeStriker } from '../lib/request_handlers';

const router = express.Router();

router.put('/initialize-striker', initializeStriker);

export default router;
