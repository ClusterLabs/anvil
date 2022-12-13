import express from 'express';

import { getUser } from '../lib/request_handlers/user';

const router = express.Router();

router.get('/', getUser);

export default router;
