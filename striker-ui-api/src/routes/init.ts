import express from 'express';

import { assertInit } from '../middlewares';

import { setMapNetwork } from '../lib/request_handlers/command';
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
        query: { command, start },
      } = request;

      if (command) return next();

      return response.redirect(
        `/api/init${path}?command=anvil-configure-host&start=${start}`,
      );
    },
    assertInit({
      fail: ({ url }, response) => {
        response.redirect(307, `/api${url}`);
      },
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
  )
  .put(
    '/set-map-network',
    assertInit({
      fail: ({ path }, response) =>
        response.redirect(307, `/api/command${path}`),
    }),
    setMapNetwork,
  );

export default router;
