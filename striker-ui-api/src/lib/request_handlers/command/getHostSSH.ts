import assert from 'assert';
import { RequestHandler } from 'express';

import {
  HOST_KEY_CHANGED_PREFIX,
  REP_IPV4,
  REP_PEACEFUL_STRING,
} from '../../consts';

import { getPeerData, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const getHostSSH: RequestHandler<
  unknown,
  GetHostSshResponseBody | ErrorResponseBody,
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

  let rsbody: GetHostSshResponseBody;

  try {
    rsbody = await getPeerData(target, { password, port });
  } catch (error) {
    const emsg = `Failed to get peer data; CAUSE: ${error}`;

    perr(emsg);

    const rserror: ErrorResponseBody = {
      code: 'fe14fb1',
      message: emsg,
      name: 'AccessError',
    };

    return response.status(500).send(rserror);
  }

  let states: [string, string][];

  try {
    states = await query<[stateUuid: string, hostUuid: string][]>(`
      SELECT a.state_uuid, a.state_host_uuid
      FROM states AS a
      WHERE a.state_name = '${HOST_KEY_CHANGED_PREFIX}${target}';`);
  } catch (error) {
    const emsg = `Failed to list SSH key conflicts; CAUSE: ${error}`;

    perr(emsg);

    const rserror: ErrorResponseBody = {
      code: 'd5a2acf',
      message: emsg,
      name: 'AccessError',
    };

    return response.status(500).send(rserror);
  }

  if (states.length > 0) {
    rsbody.badSshKeys = states.reduce<DeleteSshKeyConflictRequestBody>(
      (previous, state) => {
        const [stateUuid, hostUuid] = state;

        const { [hostUuid]: list = [] } = previous;

        list.push(stateUuid);

        previous[hostUuid] = list;

        return previous;
      },
      {},
    );
  }

  response.status(200).send(rsbody);
};
