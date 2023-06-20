import { Router } from 'express';

import anvilRouter from './anvil';
import commandRouter from './command';
import echoRouter from './echo';
import fenceRouter from './fence';
import fileRouter from './file';
import hostRouter from './host';
import jobRouter from './job';
import manifestRouter from './manifest';
import networkInterfaceRouter from './network-interface';
import serverRouter from './server';
import sshKeyRouter from './ssh-key';
import upsRouter from './ups';
import userRouter from './user';

const routes: Readonly<Record<string, Router>> = {
  anvil: anvilRouter,
  command: commandRouter,
  echo: echoRouter,
  fence: fenceRouter,
  file: fileRouter,
  host: hostRouter,
  job: jobRouter,
  manifest: manifestRouter,
  'network-interface': networkInterfaceRouter,
  server: serverRouter,
  'ssh-key': sshKeyRouter,
  ups: upsRouter,
  user: userRouter,
};

export default routes;
