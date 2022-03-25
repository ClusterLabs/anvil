import { Router } from 'express';

import anvilRouter from './anvil';
import echoRouter from './echo';
import fileRouter from './file';
import serverRouter from './server';

const routes: Readonly<Record<string, Router>> = {
  anvil: anvilRouter,
  echo: echoRouter,
  file: fileRouter,
  server: serverRouter,
};

export default routes;
