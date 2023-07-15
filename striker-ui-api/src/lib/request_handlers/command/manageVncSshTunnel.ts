import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID } from '../../consts';

import { vncpipe } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr, stdoutVar } from '../../shell';

export const manageVncSshTunnel: RequestHandler<
  unknown,
  { forwardPort: number; protocol: string },
  { open: boolean; serverUuid: string }
> = async (request, response) => {
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

  stdoutVar({ isOpen, serverUuid }, 'Manage VNC SSH tunnel params: ');

  let operation = 'close';

  if (isOpen) {
    operation = 'open';
  }

  let rsbody: { forwardPort: number; protocol: string };

  try {
    rsbody = await vncpipe(serverUuid, isOpen);
  } catch (error) {
    stderr(
      `Failed to ${operation} VNC SSH tunnel to server ${serverUuid}; CAUSE: ${error}`,
    );

    return response.status(500).send();
  }

  return response.json(rsbody);
};
