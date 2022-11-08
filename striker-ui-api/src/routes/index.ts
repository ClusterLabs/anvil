import { Router } from 'express';

import anvilRouter from './anvil';
import commandRouter from './command';
import echoRouter from './echo';
import fileRouter from './file';
import hostRouter from './host';
import jobRouter from './job';
import networkInterfaceRouter from './network-interface';
import serverRouter from './server';
import sshKeyRouter from './ssh-key';
import userRouter from './user';

const routes: Readonly<Record<string, Router>> = {
  anvil: anvilRouter,
  command: commandRouter,
  echo: echoRouter,
  file: fileRouter,
  host: hostRouter,
  job: jobRouter,
  'network-interface': networkInterfaceRouter,
  server: serverRouter,
  'ssh-key': sshKeyRouter,
  user: userRouter,
};

export default routes;
