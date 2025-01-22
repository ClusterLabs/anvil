import express from 'express';
import { existsSync } from 'fs';

import { SERVER_PATHS } from '../lib/consts';

import { assertAuthentication, assertInit } from '../middlewares';
import { pout, poutvar } from '../lib/shell';

const router = express.Router();

const htmlDir = SERVER_PATHS.var.www.html.self;

router.use((...args) => {
  const [request, response, next] = args;
  const { originalUrl, path: initialPath } = request;

  poutvar({
    initialPath,
    originalUrl,
  });

  let path = initialPath;

  if (path.slice(-1) === '/') {
    if (path.length > 1) {
      const q = originalUrl.slice(path.length);
      const p = path.slice(0, -1).replace(/\/+/g, '/');
      const t = `${p}${q}`;

      poutvar({ redirect: t });

      return response.redirect(t);
    } else {
      path = '/index';
    }
  }

  const exted = /\.html$/.test(path) ? path : `${path}.html`;
  const fpath = `${htmlDir}${exted}`;
  const htmlExists = existsSync(fpath);

  pout(`static:[${path}] requested; html=${htmlExists}`);

  // Request for asset, i.e., image, script.
  if (!htmlExists) return next();

  return assertInit({
    // When not configured, redirect to the init page.
    fail: (rq, rs, nx) => {
      const { path: p } = rq;
      const target = '/init';

      // Prevent browsers from caching the initialize page to enable redirect
      // after the init restart.
      rs.setHeader('Cache-Control', 'must-revalidate, no-store');

      if (p.startsWith(target)) return nx();

      return rs.redirect(target);
    },
    invert: true,
    // When configured, check whether user is authenticated.
    succeed: assertAuthentication({
      fail: (rt, rq, rs, nx) => {
        const { path: p } = rq;
        const target = '/login';

        if (p.startsWith(target)) return nx();

        return rs.redirect(rt ? `${target}?rt=${rt}` : target);
      },
      failReturnTo: !path.startsWith('/login'),
      succeed: (rq, rs, nx) => {
        const {
          path: p,
          query: { re: reinit, rt = '/' },
        } = rq;

        // Redirect to home or the given return-to path when the user is already
        // authenticated.
        if (p.startsWith('/login')) return rs.redirect(String(rt));

        // Redirect to home when the user tries to access the init page after
        //   1) the system is already initialized, and
        //   2) the user is already authenticated.
        if (p.startsWith('/init') && !reinit) return rs.redirect('/');

        return nx();
      },
    }),
  })(...args);
}, express.static(htmlDir, { extensions: ['html'] }));

export default router;
