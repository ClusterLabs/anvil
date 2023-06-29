import express from 'express';

import {
  createFence,
  deleteFence,
  getFence,
  getFenceTemplate,
  updateFence,
} from '../lib/request_handlers/fence';

const router = express.Router();

router
  .delete('/:uuid?', deleteFence)
  .get('/', getFence)
  .get('/template', getFenceTemplate)
  .post('/', createFence)
  .put('/:uuid', updateFence);

export default router;
