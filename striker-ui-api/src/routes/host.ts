import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  createHost,
  createHostConnection,
  deleteHostConnection,
  getHost,
  getHostAlt,
  getHostConnection,
  getHostDetail,
  getHostDetailAlt,
  getHostNicModels,
  prepareHost,
  updateHost,
} from '../lib/request_handlers/host';

const single = express.Router();

single.get('/alt', getHostDetailAlt).get('/nic-model', getHostNicModels);

const router = express.Router();

router
  .get('/', getHost)
  .get('/alt', getHostAlt)
  .get('/:hostUUID', getHostDetail)
  .post('/', createHost)
  .put('/prepare', prepareHost)
  .put('/:hostUUID?', updateHost);

router
  .route('/connection')
  .get(getHostConnection)
  .post(createHostConnection)
  .delete(deleteHostConnection);

router.use('/:uuid', validateRequestTarget(), single);

export default router;
