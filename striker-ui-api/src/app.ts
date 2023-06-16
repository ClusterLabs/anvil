import cors from 'cors';
import express, { json } from 'express';

import { GUARD_API } from './lib/consts';

import { guardApi, passport, session } from './middlewares';
import routes from './routes';
import { rrouters } from './lib/rrouters';

export default (async () => {
  const app = express();

  app.use(json());

  app.use(
    cors({
      origin: true,
      credentials: true,
    }),
  );

  // Add session handler to the chain **after** adding other handlers that do
  // not depend on session(s).
  app.use(await session);

  app.use(passport.initialize());
  app.use(passport.authenticate('session'));

  rrouters(app, routes.private, {
    assign: GUARD_API ? (router) => [guardApi, router] : undefined,
    route: '/api',
  });
  rrouters(app, routes.public, { route: '/api' });

  app.use(routes.static);

  return app;
})();
