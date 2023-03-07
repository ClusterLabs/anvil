import express from 'express';

import { getManifest } from '../lib/request_handlers/manifest';

const router = express.Router();

router.get('/', getManifest);

export default router;
