import express from 'express';

import { deleteUps, getUPS, getUPSTemplate } from '../lib/request_handlers/ups';

const router = express.Router();

router
  .delete('/:uuid?', deleteUps)
  .get('/', getUPS)
  .get('/template', getUPSTemplate);

export default router;
