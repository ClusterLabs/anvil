import { Router } from 'express';

import anvilRouter from './anvil';
import commandRouter from './command';
import echoRouter from './echo';
import fileRouter from './file';
import hostRouter from './host';
import networkInterfaceRouter from './network-interface';
import serverRouter from './server';

const routes: Readonly<Record<string, Router>> = {
  anvil: anvilRouter,
  command: commandRouter,
  echo: echoRouter,
  file: fileRouter,
  host: hostRouter,
  'network-interface': networkInterfaceRouter,
  server: serverRouter,
};

export default routes;
