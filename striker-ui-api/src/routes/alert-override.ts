import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  createAlertOverride,
  deleteAlertOverride,
  getAlertOverride,
  getAlertOverrideDetail,
  updateAlertOverride,
} from '../lib/request_handlers/alert-override';

const single = express.Router();

single
  .delete('/', deleteAlertOverride)
  .get('/', getAlertOverrideDetail)
  .put('/', updateAlertOverride);

const router = express.Router();

router.get('/', getAlertOverride).post('/', createAlertOverride);

router.use('/:uuid', validateRequestTarget(), single);

export default router;
