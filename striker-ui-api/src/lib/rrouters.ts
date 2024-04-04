import { Application, Handler, Router } from 'express';
import path from 'path';

import { pout } from './shell';

export const rrouters = <
  A extends Application,
  M extends MapToRouter<R>,
  R extends Router,
  H extends Handler,
>(
  app: A,
  union: Readonly<M> | R,
  {
    assign = (router) => [router],
    key,
    route = '/',
  }: {
    assign?: (router: R) => Array<R | H>;
    key?: keyof M;
    route?: string;
  } = {},
) => {
  if ('route' in union) {
    const handlers = assign(union as R);
    const { length: hcount } = handlers;

    pout(`Set up route ${route} with ${hcount} handler(s)`);

    app.use(route, ...handlers);
  } else if (key) {
    rrouters(app, union[key], {
      assign,
      route: path.posix.join(route, String(key)),
    });
  } else {
    Object.entries(union).forEach(([extend, subunion]) => {
      rrouters(app, subunion, {
        assign,
        route: path.posix.join(route, extend),
      });
    });
  }
};
