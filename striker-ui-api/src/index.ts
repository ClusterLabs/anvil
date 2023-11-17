import { getgid, getuid, setgid, setuid } from 'process';

import { PGID, PUID, PORT, ECODE_DROP_PRIVILEGES } from './lib/consts';

import app from './app';
import { proxyServerVncUpgrade } from './middlewares';
import { stderr, stdout } from './lib/shell';

(async () => {
  stdout(`Starting main process with ownership ${getuid()}:${getgid()}`);

  const server = (await app).listen(PORT, () => {
    try {
      // Group must be set before user to avoid permission error.
      setgid(PGID);
      setuid(PUID);

      stdout(`Main process ownership changed to ${getuid()}:${getgid()}.`);
    } catch (error) {
      stderr(`Failed to change main process ownership; CAUSE: ${error}`);

      process.exit(ECODE_DROP_PRIVILEGES);
    }

    stdout(`Listening on localhost:${PORT}.`);
  });

  server.on('upgrade', proxyServerVncUpgrade);
})();
