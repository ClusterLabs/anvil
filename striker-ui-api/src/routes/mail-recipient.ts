import express from 'express';

import {
  createMailRecipient,
  deleteMailRecipient,
  getMailRecipient,
  getMailRecipientDetail,
  updateMailRecipient,
} from '../lib/request_handlers/mail-recipient';

const router = express.Router();

router
  .delete('/:uuid', deleteMailRecipient)
  .get('/', getMailRecipient)
  .get('/:uuid', getMailRecipientDetail)
  .post('/', createMailRecipient)
  .put('/:uuid', updateMailRecipient);

export default router;
