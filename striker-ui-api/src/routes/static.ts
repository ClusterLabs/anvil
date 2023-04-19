import express from 'express';

import { SERVER_PATHS } from '../lib/consts';

const router = express.Router();

router.use(
  express.static(SERVER_PATHS.var.www.html.self, {
    extensions: ['htm', 'html'],
  }),
);

export default router;
