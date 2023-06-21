import express from 'express';

import { deleteUser, getUser } from '../lib/request_handlers/user';

const router = express.Router();

router
  .get('/', getUser)
  .delete('/', deleteUser)
  .delete('/:userUuid', deleteUser);

export default router;
