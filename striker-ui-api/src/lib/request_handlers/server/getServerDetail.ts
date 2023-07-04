import assert from 'assert';
import { RequestHandler } from 'express';
import { existsSync, readFileSync } from 'fs';
import path from 'path';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { sanitize } from '../../sanitize';
import { stderr, stdout, stdoutVar } from '../../shell';

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
    const imageFileName = `${serverUuid}_screenshot`;
    const imageFilePath = path.join(SERVER_PATHS.tmp.self, imageFileName);

    stdoutVar(
      { imageFileName, imageFilePath },
      `Server ${serverUuid} image file: `,
    );

    const rsbody = { screenshot: '' };

    if (existsSync(imageFilePath)) {
      try {
        rsbody.screenshot = readFileSync(imageFilePath, { encoding: 'utf-8' });
      } catch (error) {
        stderr(
          `Failed to read image file at ${imageFilePath}; CAUSE: ${error}`,
        );

        return response.status(500).send();
      }
    }

    return response.send(rsbody);
  } else {
    // For getting sever detail data.

    response.send();
  }
};
