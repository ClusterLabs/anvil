import { getgid, getuid, setgid, setuid } from 'process';

import { PGID, PUID, PORT, ECODE_DROP_PRIVILEGES } from './lib/consts';

import app from './app';
import { stderr, stdout } from './lib/shell';

(async () => {
  stdout(`Starting process with ownership ${getuid()}:${getgid()}`);

  (await app).listen(PORT, () => {
    try {
      // Group must be set before user to avoid permission error.
      setgid(PGID);
      setuid(PUID);

      stdout(`Process ownership changed to ${getuid()}:${getgid()}.`);
    } catch (error) {
      stderr(`Failed to change process ownership; CAUSE: ${error}`);

      process.exit(ECODE_DROP_PRIVILEGES);
    }

    stdout(`Listening on localhost:${PORT}.`);
  });
})();
