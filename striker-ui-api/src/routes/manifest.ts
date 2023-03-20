import express from 'express';

import {
  deleteManifest,
  getManifest,
  getManifestDetail,
  getManifestTemplate,
} from '../lib/request_handlers/manifest';

const router = express.Router();

router
  .get('/', getManifest)
  .get('/template', getManifestTemplate)
  .get('/:manifestUUID', getManifestDetail)
  .delete('/', deleteManifest)
  .delete('/manifestUuid', deleteManifest);

export default router;
