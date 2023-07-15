import express from 'express';

import {
  createUps,
  deleteUps,
  getUPS,
  getUPSTemplate,
  updateUps,
} from '../lib/request_handlers/ups';

const router = express.Router();

router
  .delete('/:uuid?', deleteUps)
  .get('/', getUPS)
  .get('/template', getUPSTemplate)
  .post('/', createUps)
  .put('/:uuid', updateUps);

export default router;
