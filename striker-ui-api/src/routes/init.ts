import express from 'express';

import { assertInit } from '../middlewares';

import { setMapNetwork } from '../lib/request_handlers/command';
import { configStriker } from '../lib/request_handlers/host';
import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router
  .get(
    '/network-interface/:hostUUID?',
    assertInit({
      fail: ({ path }, response) => response.redirect(`/api${path}`),
    }),
    getNetworkInterface,
  )
  .post(
    '/',
    assertInit({
      fail: (request, response) => response.redirect(`/api/host`),
    }),
    configStriker,
  )
  .put(
    '/set-map-network',
    assertInit({
      fail: ({ path }, response) => response.redirect(`/api/command${path}`),
    }),
    setMapNetwork,
  );

export default router;
