import express from 'express';

import {
  createManifest,
  deleteManifest,
  getManifest,
  getManifestDetail,
  getManifestTemplate,
  updateManifest,
} from '../lib/request_handlers/manifest';

const router = express.Router();

router
  .delete('/', deleteManifest)
  .delete('/:manifestUuid', deleteManifest)
  .get('/', getManifest)
  .get('/template', getManifestTemplate)
  .get('/:manifestUUID', getManifestDetail)
  .post('/', createManifest)
  .put('/:manifestUuid', updateManifest);

export default router;
