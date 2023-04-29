import cors from 'cors';
import express, { json } from 'express';

import { guardApi } from './lib/assertAuthentication';
import passport from './passport';
import routes from './routes';
import { rrouters } from './lib/rrouters';
import session from './session';
import { stdout } from './lib/shell';

export default (async () => {
  const app = express();

  app.use(json());

  app.use(
    cors({
      origin: (requestOrigin, done) => {
        stdout(`Request header: Origin=${requestOrigin}`);

        done(null, requestOrigin);
      },
      credentials: true,
    }),
  );

  // Add session handler to the chain **after** adding other handlers that do
  // not depend on session(s).
  app.use(await session);

  app.use(passport.initialize());
  app.use(passport.authenticate('session'));

  rrouters(app, routes.private, {
    assign: (router) => [guardApi, router],
    route: '/api',
  });
  rrouters(app, routes.public, { route: '/api' });

  app.use(routes.static);

  return app;
})();
