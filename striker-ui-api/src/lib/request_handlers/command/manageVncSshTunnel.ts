import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID } from '../../consts';

import { sanitize } from '../../sanitize';
import { stderr, vncpipe } from '../../shell';

export const manageVncSshTunnel: RequestHandler<
  unknown,
  { forwardPort: number; protocol: string },
  { open: boolean; serverUuid: string }
> = (request, response) => {
  const { body: { open: rOpen, serverUuid: rServerUuid } = {} } = request;

  const isOpen = sanitize(rOpen, 'boolean');
  const serverUuid = sanitize(rServerUuid, 'string');

  try {
    assert(
      REP_UUID.test(serverUuid),
      `Server UUID must be a valid UUIDv4; got: [${serverUuid}]`,
    );
  } catch (error) {
    stderr(`Assert input failed when manage VNC SSH tunnel; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let cstdout = '';

  try {
    cstdout = vncpipe(
      '--server-uuid',
      serverUuid,
      '--component',
      'st',
      isOpen ? '--open' : '',
    );
  } catch (error) {
    stderr(
      `Failed to ${
        isOpen ? 'open' : 'close'
      } VNC SSH tunnel to server ${serverUuid}; CAUSE: ${error}`,
    );

    return response.status(500).send();
  }

  const coutput = cstdout
    .split(/\s*,\s*/)
    .reduce<Record<string, string>>((previous, pair: string) => {
      const [key, value] = pair.split(/\s*:\s*/, 2);

      previous[key] = value;

      return previous;
    }, {});

  let forwardPort: number;
  let protocol: string;

  try {
    assert('forwardPort' in coutput, 'Missing forward port in command output');
    assert('protocol' in coutput, 'Missing protocol in command output');

    forwardPort = Number.parseInt(coutput.forwardPort);
    protocol = coutput.protocol;
  } catch (error) {
    stderr(`Failed to get VNC SSH tunnel connect info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.json({
    forwardPort,
    protocol,
  });
};
