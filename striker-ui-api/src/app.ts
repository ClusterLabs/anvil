import cors from 'cors';
import express, { json } from 'express';

import { assertAuthentication } from './lib/assertAuthentication';
import passport from './passport';
import routes from './routes';
import { rrouters } from './lib/rrouters';
import sessionHandler from './session';

const app = express();

app.use(json());

app.use(cors());

// Add session handler to the chain **after** adding other handlers that do
// not depend on session(s).
app.use(sessionHandler);

app.use(passport.initialize());
app.use(passport.authenticate('session'));

const authenticationHandler = assertAuthentication();

rrouters(app, routes, {
  assign: (router) => [authenticationHandler, router],
  key: 'api',
});
rrouters(app, routes, { key: 'auth' });
rrouters(app, routes, { key: 'echo' });

export default app;
