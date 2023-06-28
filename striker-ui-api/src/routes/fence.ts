import express from 'express';

import {
  deleteFence,
  getFence,
  getFenceTemplate,
} from '../lib/request_handlers/fence';

const router = express.Router();

router
  .delete('/:uuid?', deleteFence)
  .get('/', getFence)
  .get('/template', getFenceTemplate);

export default router;
