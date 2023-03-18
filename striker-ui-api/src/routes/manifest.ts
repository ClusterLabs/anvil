import express from 'express';

import {
  getManifest,
  getManifestDetail,
  getManifestTemplate,
} from '../lib/request_handlers/manifest';

const router = express.Router();

router
  .get('/', getManifest)
  .get('/template', getManifestTemplate)
  .get('/:manifestUUID', getManifestDetail);

export default router;
