import express from 'express';

import {
  deleteSSHKeyConflict,
  getSSHKeyConflict,
} from '../lib/request_handlers/ssh-key';

const router = express.Router();

router
  .get('/conflict', getSSHKeyConflict)
  .delete('/conflict', deleteSSHKeyConflict);

export default router;
