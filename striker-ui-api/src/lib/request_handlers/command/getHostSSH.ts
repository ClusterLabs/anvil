import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_IPV4, REP_PEACEFUL_STRING } from '../../consts';
import { HOST_KEY_CHANGED_PREFIX } from '../../consts/HOST_KEY_CHANGED_PREFIX';

import { getLocalHostUUID, getPeerData, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const getHostSSH: RequestHandler<
  unknown,
  GetHostSshResponseBody,
  GetHostSshRequestBody
> = async (request, response) => {
  const {
    body: { password: rPassword, port: rPort = 22, ipAddress: rTarget } = {},
  } = request;

  const password = sanitize(rPassword, 'string');
  const port = sanitize(rPort, 'number');
  const target = sanitize(rTarget, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_PEACEFUL_STRING.test(password),
      `Password must be a peaceful string; got [${password}]`,
    );

    assert(
      Number.isInteger(port),
      `Port must be a valid integer; got [${port}]`,
    );

    assert(
      REP_IPV4.test(target),
      `IP address must be a valid IPv4 address; got [${target}]`,
    );
  } catch (assertError) {
    perr(`Assert failed when getting host SSH data; CAUSE: ${assertError}`);

    return response.status(400).send();
  }

  const localHostUUID = getLocalHostUUID();

  let rsbody: GetHostSshResponseBody;

  try {
    rsbody = await getPeerData(target, { password, port });
  } catch (subError) {
    perr(`Failed to get peer data; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  if (!rsbody.isConnected) {
    const rows: [stateNote: string, stateUUID: string][] = await query(`
      SELECT sta.state_note, sta.state_uuid
      FROM states AS sta
      WHERE sta.state_host_uuid = '${localHostUUID}'
        AND sta.state_name = '${HOST_KEY_CHANGED_PREFIX}${target}';`);

    if (rows.length > 0) {
      rsbody.badSSHKeys = rows.reduce<DeleteSshKeyConflictRequestBody>(
        (previous, [, stateUUID]) => {
          previous[localHostUUID].push(stateUUID);

          return previous;
        },
        { [localHostUUID]: [] },
      );
    }
  }

  response.status(200).send(rsbody);
};
