import express from 'express';

import {
  createMailServer,
  deleteMailServer,
  getMailServer,
  getMailServerDetail,
  updateMailServer,
} from '../lib/request_handlers/mail-server';

const router = express.Router();

router
  .delete('/:uuid', deleteMailServer)
  .get('/', getMailServer)
  .get('/:uuid', getMailServerDetail)
  .post('/', createMailServer)
  .put('/:uuid', updateMailServer);

export default router;
