import express from 'express';

import { assertInit } from '../middlewares';

import { setMapNetwork } from '../lib/request_handlers/command';
import { configStriker } from '../lib/request_handlers/host';
import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router.use(assertInit());

router
  .get('/network-interface', getNetworkInterface)
  .post('/', configStriker)
  .put('/set-map-network', setMapNetwork);

export default router;
