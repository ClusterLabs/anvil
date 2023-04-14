import anvilRouter from './anvil';
import authRouter from './auth';
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

const routes = {
  api: {
    anvil: anvilRouter,
    command: commandRouter,
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
  },
  auth: authRouter,
  echo: echoRouter,
};

export default routes;
