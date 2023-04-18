import express from 'express';

import { assertAuthentication } from '../lib/assertAuthentication';
import { login, logout } from '../lib/request_handlers/auth';
import passport from '../passport';

const router = express.Router();

router
  .post('/login', passport.authenticate('login'), login)
  .put('/logout', assertAuthentication(), logout);

export default router;
