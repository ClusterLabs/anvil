import express from 'express';

import getAnvil from '../lib/request_handlers/anvil/getAnvil';

const router = express.Router();

router.get('/', getAnvil);

export default router;
