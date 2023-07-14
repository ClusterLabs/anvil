import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { sanitize } from '../../sanitize';
import { stderr, stdout } from '../../shell';
import { execSync } from 'child_process';

export const getServerDetail: RequestHandler<
  ServerDetailParamsDictionary,
  unknown,
  unknown,
  ServerDetailParsedQs
> = async (request, response) => {
  const {
    params: { serverUUID: serverUuid },
    query: { ss },
  } = request;

  const isScreenshot = sanitize(ss, 'boolean');

  stdout(`serverUUID=[${serverUuid}],isScreenshot=[${isScreenshot}]`);

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

  if (isScreenshot) {
    const rsbody = { screenshot: '' };

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
  } else {
    // For getting sever detail data.

    response.send();
  }
};
