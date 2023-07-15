import express from 'express';

import { login, logout } from '../lib/request_handlers/auth';
import { guardApi, passport } from '../middlewares';

const router = express.Router();

router
  .post('/login', passport.authenticate('login'), login)
  .put('/logout', guardApi, logout);

export default router;
