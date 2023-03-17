import express from 'express';

import {
  getManifest,
  getManifestTemplate,
} from '../lib/request_handlers/manifest';

const router = express.Router();

router.get('/', getManifest).get('/template', getManifestTemplate);

export default router;
