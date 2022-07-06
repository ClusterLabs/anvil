import { Router } from 'express';

import anvilRouter from './anvil';
import echoRouter from './echo';
import fileRouter from './file';
import networkInterfaceRouter from './network-interface';
import serverRouter from './server';

const routes: Readonly<Record<string, Router>> = {
  anvil: anvilRouter,
  echo: echoRouter,
  file: fileRouter,
  'network-interface': networkInterfaceRouter,
  server: serverRouter,
};

export default routes;
