import express from 'express';

import { getSSHKey } from '../lib/request_handlers/ssh-key';

const router = express.Router();

router.get('/', getSSHKey);

export default router;
