import express from 'express';

import {
  createUser,
  deleteUser,
  getUser,
  updateUser,
} from '../lib/request_handlers/user';

const router = express.Router();

router
  .get('/', getUser)
  .post('/', createUser)
  .put('/:userUuid', updateUser)
  .delete('/', deleteUser)
  .delete('/:userUuid', deleteUser);

export default router;
