import express from 'express';

import { assertInit } from '../middlewares';

import { configStriker } from '../lib/request_handlers/host';
import { getJob } from '../lib/request_handlers/job';
import { getNetworkInterface } from '../lib/request_handlers/network-interface';

const router = express.Router();

router
  .get(
    '/job',
    (request, response, next) => {
      const {
        path,
        query: { command },
      } = request;

      const script = 'anvil-configure-host';

      if (command === script) return next();

      return response.redirect(`/api/init${path}?command=${script}`);
    },
    assertInit({
      fail: (request, response, next) => next(),
    }),
    getJob,
  )
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
