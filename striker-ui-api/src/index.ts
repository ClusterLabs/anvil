import { getgid, getuid, setgid, setuid } from 'process';

import { PGID, PUID, PORT, ECODE_DROP_PRIVILEGES } from './lib/consts';

import { access } from './lib/accessModule';
import { perr, pout } from './lib/shell';
import { workspace } from './lib/workspace';

// Prepare the workspace before trying to establish access
workspace.mkdir(PUID, PGID);

/**
 * Wait until the anvil-access-module daemon finishes its setup before doing
 * anything else.
 *
 * Notes:
 * * The webpackMode directive tells webpack to include the dynamic module into
 *   the main bundle. Webpack defaults to put such modules in separate files to
 *   reduce the amount of loading.
 */
access.default.once('active', async () => {
  const { default: app } = await import(/* webpackMode: "eager" */ './app');
  const { proxyServerVncUpgrade } = await import(
    /* webpackMode: "eager" */ './middlewares'
  );

  pout(`Starting main process with ownership ${getuid()}:${getgid()}`);

  const server = (await app).listen(PORT, () => {
    try {
      // Group must be set before user to avoid permission error.
      setgid(PGID);
      setuid(PUID);

      pout(`Main process ownership changed to ${getuid()}:${getgid()}.`);
    } catch (error) {
      perr(`Failed to change main process ownership; CAUSE: ${error}`);

      process.exit(ECODE_DROP_PRIVILEGES);
    }

    pout(`Listening on localhost:${PORT}.`);
  });

  server.on('upgrade', proxyServerVncUpgrade);

  const handleSig: NodeJS.SignalsListener = (signal) => {
    pout(`Main process received signal ${signal}.`);

    server.close((error) => {
      perr(`Failed to close express app; CAUSE: ${error}`);
    });

    access.default.stop();
  };

  const sigs: NodeJS.Signals[] = ['SIGALRM', 'SIGINT', 'SIGTERM'];

  sigs.forEach((sig) => {
    process.once(sig, handleSig);
  });
});
