import { Application, Router } from 'express';
import path from 'path';

import { stdout } from './shell';

export const rrouters = <
  A extends Application,
  M extends MapToRouter,
  R extends Router,
>(
  app: A,
  union: Readonly<M> | R,
  { key, route = '/' }: { key?: string; route?: string } = {},
) => {
  if ('route' in union) {
    stdout(`Setting up route ${route}`);
    app.use(route, union as R);
  } else if (key) {
    rrouters(app, union[key], { route: path.posix.join(route, key) });
  } else {
    Object.entries(union).forEach(([extend, subunion]) => {
      rrouters(app, subunion, { route: path.posix.join(route, extend) });
    });
  }
};
