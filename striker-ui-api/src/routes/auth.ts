import express from 'express';

import { login } from '../lib/request_handlers/auth';
import passport from '../passport';

const router = express.Router();

router.post('/login', passport.authenticate('login'), login);

export default router;
