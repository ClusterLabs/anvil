import express from 'express';
import { existsSync } from 'fs';
import path from 'path';

import { SERVER_PATHS } from '../lib/consts';

import { assertAuthentication } from '../lib/assertAuthentication';
import { stdout } from '../lib/shell';

const router = express.Router();

const htmlDir = SERVER_PATHS.var.www.html.self;

router.use(
  (...args) => {
    const { 0: request, 2: next } = args;
    const { originalUrl } = request;

    if (/^[/]login/.test(originalUrl)) {
      stdout(`Static:login requested`);

      return assertAuthentication({
        fail: (rt, rq, rs, nx) => nx(),
        succeed: '/',
      })(...args);
    }

    const parts = originalUrl.replace(/[/]$/, '').split('/');
    const tail = parts.pop() || 'index';
    const extended = /[.]html$/.test(tail) ? tail : `${tail}.html`;

    parts.push(extended);

    const htmlPath = path.posix.join(htmlDir, ...parts);
    const isHtmlExists = existsSync(htmlPath);

    if (isHtmlExists) {
      stdout(`Static:[${htmlPath}] requested`);

      return assertAuthentication({ fail: '/login', failReturnTo: true })(
        ...args,
      );
    }

    return next();
  },
  express.static(htmlDir, {
    extensions: ['htm', 'html'],
  }),
);

export default router;
