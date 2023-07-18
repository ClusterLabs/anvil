import assert from 'assert';
import { execSync } from 'child_process';
import { RequestHandler } from 'express';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { getVncinfo } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { stderr, stdout } from '../../shell';

export const getServerDetail: RequestHandler<
  ServerDetailParamsDictionary,
  unknown,
  unknown,
  ServerDetailParsedQs
> = async (request, response) => {
  const {
    params: { serverUUID: serverUuid },
    query: { ss: rSs, vnc: rVnc },
  } = request;

  const ss = sanitize(rSs, 'boolean');
  const vnc = sanitize(rVnc, 'boolean');

  stdout(`serverUUID=[${serverUuid}],isScreenshot=[${ss}]`);

  try {
    assert(
      REP_UUID.test(serverUuid),
      `Server UUID must be a valid UUID; got [${serverUuid}]`,
    );
  } catch (assertError) {
    stderr(
      `Failed to assert value when trying to get server detail; CAUSE: ${assertError}.`,
    );

    return response.status(500).send();
  }

  if (ss) {
    const rsbody: ServerDetailScreenshot = { screenshot: '' };

    try {
      rsbody.screenshot = execSync(
        `${SERVER_PATHS.usr.sbin['anvil-get-server-screenshot'].self} --convert --resize 500x500 --server-uuid '${serverUuid}'`,
        { encoding: 'utf-8' },
      );
    } catch (error) {
      stderr(`Failed to server ${serverUuid} screenshot; CAUSE: ${error}`);

      return response.status(500).send();
    }

    return response.send(rsbody);
  } else if (vnc) {
    let rsbody: ServerDetailVncInfo;

    try {
      rsbody = await getVncinfo(serverUuid);
    } catch (error) {
      stderr(`Failed to get server ${serverUuid} VNC info; CAUSE: ${error}`);

      return response.status(500).send();
    }

    return response.send(rsbody);
  } else {
    // For getting sever detail data.

    response.send();
  }
};
