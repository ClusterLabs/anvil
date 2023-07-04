import express from 'express';
import { existsSync } from 'fs';

import { SERVER_PATHS } from '../lib/consts';

import { assertAuthentication, assertInit } from '../middlewares';
import { stdout } from '../lib/shell';

const router = express.Router();

const htmlDir = SERVER_PATHS.var.www.html.self;

router.use((...args) => {
  const [request, response, next] = args;
  const { originalUrl, path: initialPath } = request;

  console.log(`originalUrl=${originalUrl},initialpath=${initialPath}`);

  let path = initialPath;

  if (path.slice(-1) === '/') {
    if (path.length > 1) {
      const q = originalUrl.slice(path.length);
      const p = path.slice(0, -1).replace(/\/+/g, '/');
      const t = `${p}${q}`;

      console.log(`redirect=${t}`);

      return response.redirect(t);
    } else {
      path = '/index';
    }
  }

  const exted = /\.html$/.test(path) ? path : `${path}.html`;
  const fpath = `${htmlDir}${exted}`;
  const htmlExists = existsSync(fpath);

  stdout(`static:[${path}] requested; html=${htmlExists}`);

  // Request for asset, i.e., image, script.
  if (!htmlExists) return next();

  return assertInit({
    // When not configured, redirect to the init page.
    fail: (rq, rs, nx) => {
      const { path: p } = rq;
      const target = '/init';

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
    }),
  })(...args);
}, express.static(htmlDir, { extensions: ['html'] }));

export default router;
