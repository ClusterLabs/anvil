import express from 'express';

import { validateRequestTarget } from '../middlewares';
import {
  createMailRecipient,
  deleteMailRecipient,
  getMailRecipient,
  getMailRecipientDetail,
  updateMailRecipient,
} from '../lib/request_handlers/mail-recipient';

const single = express.Router();

single
  .delete('/', deleteMailRecipient)
  .get('/', getMailRecipientDetail)
  .put('/', updateMailRecipient);

const router = express.Router();

router.get('/', getMailRecipient).post('/', createMailRecipient);

router.use('/:uuid', validateRequestTarget(), single);

export default router;
