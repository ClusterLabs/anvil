import express from 'express';

import { assertInit } from '../middlewares';

import { configStriker } from '../lib/request_handlers/host';
import { getJobDetail } from '../lib/request_handlers/job';
import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router
  .get('/job/:uuid', getJobDetail)
  .get(
    '/network-interface/:hostUUID?',
    assertInit({
      fail: ({ path }, response) => response.redirect(307, `/api${path}`),
    }),
    getNetworkInterface,
  )
  .put(
    '/',
    assertInit({
      fail: (request, response) =>
        response.redirect(307, `/api/host?handler=striker`),
    }),
    configStriker,
  );

export default router;
