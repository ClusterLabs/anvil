import express from 'express';

import {
  createAlertOverride,
  deleteAlertOverride,
  getAlertOverride,
  getAlertOverrideDetail,
  updateAlertOverride,
} from '../lib/request_handlers/alert-override';

const router = express.Router();

router
  .delete('/:uuid', deleteAlertOverride)
  .get('/', getAlertOverride)
  .get('/:uuid', getAlertOverrideDetail)
  .post('/', createAlertOverride)
  .put('/:uuid', updateAlertOverride);

export default router;
