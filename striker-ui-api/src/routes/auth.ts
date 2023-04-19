import express from 'express';

import { authenticationHandler } from '../lib/assertAuthentication';
import { login, logout } from '../lib/request_handlers/auth';
import passport from '../passport';

const router = express.Router();

router
  .post('/login', passport.authenticate('login'), login)
  .put('/logout', authenticationHandler, logout);

export default router;
