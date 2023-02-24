import assert from 'assert';
import { RequestHandler } from 'express';
import { createReadStream } from 'fs';
import path from 'path';

import { REP_UUID } from '../../consts/REG_EXP_PATTERNS';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { dbQuery, getLocalHostUUID, job } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { mkfifo, rm, stderr, stdout } from '../../shell';

const rmfifo = (path: string) => {
  try {
    rm(path);
  } catch (rmfifoError) {
    stderr(`Failed to clean up named pipe; CAUSE: ${rmfifoError}`);
  }
};

export const getServerDetail: RequestHandler = (request, response) => {
  const { serverUUID } = request.params;
  const { ss, resize } = request.query;

  const epoch = Date.now();
  const isScreenshot = sanitize(ss, 'boolean');

  stdout(
    `serverUUID=[${serverUUID}],epoch=[${epoch}],isScreenshot=[${isScreenshot}]`,
  );

  try {
    assert(
      REP_UUID.test(serverUUID),
      `Server UUID must be a valid UUID; got [${serverUUID}]`,
    );
  } catch (assertError) {
    stderr(
      `Failed to assert value when trying to get server detail; CAUSE: ${assertError}.`,
    );

    response.status(500).send();

    return;
  }

  if (isScreenshot) {
    let requestHostUUID: string, serverHostUUID: string;

    try {
      requestHostUUID = getLocalHostUUID();
    } catch (subError) {
      stderr(String(subError));

      response.status(500).send();

      return;
    }

    stdout(`requestHostUUID=[${requestHostUUID}]`);

    try {
      [[serverHostUUID]] = dbQuery(`
          SELECT server_host_uuid
          FROM servers
          WHERE server_uuid = '${serverUUID}';`).stdout;
    } catch (queryError) {
      stderr(`Failed to get server host UUID; CAUSE: ${queryError}`);

      response.status(500).send();

      return;
    }

    stdout(`serverHostUUID=[${serverHostUUID}]`);

    const imageFileName = `${serverUUID}_screenshot_${epoch}`;
    const imageFilePath = path.join(SERVER_PATHS.tmp.self, imageFileName);

    try {
      mkfifo(imageFilePath);

      const namedPipeReadStream = createReadStream(imageFilePath, {
        autoClose: true,
        encoding: 'utf-8',
      });

      let imageData = '';

      namedPipeReadStream.once('error', (readError) => {
        stderr(`Failed to read from named pipe; CAUSE: ${readError}`);
      });

      namedPipeReadStream.once('close', () => {
        stdout(`On close; removing named pipe at ${imageFilePath}.`);

        response.status(200).send({ screenshot: imageData });

        rmfifo(imageFilePath);
      });

      namedPipeReadStream.on('data', (data) => {
        const imageChunk = data.toString().trim();
        const peekLength = 10;

        stdout(
          `${serverUUID} image chunk: ${
            imageChunk.length > 0
              ? `${imageChunk.substring(
                  0,
                  peekLength,
                )}...${imageChunk.substring(
                  imageChunk.length - peekLength - 1,
                )}`
              : 'empty'
          }`,
        );

        imageData += imageChunk;
      });
    } catch (prepPipeError) {
      stderr(
        `Failed to prepare named pipe and/or receive image data; CAUSE: ${prepPipeError}`,
      );

      response.status(500).send();

      rmfifo(imageFilePath);

      return;
    }

    let resizeArgs = sanitize(resize, 'string');

    if (!/^\d+x\d+$/.test(resizeArgs)) {
      resizeArgs = '';
    }

    try {
      job({
        file: __filename,
        job_command: SERVER_PATHS.usr.sbin['anvil-get-server-screenshot'].self,
        job_data: `server-uuid=${serverUUID}
request-host-uuid=${requestHostUUID}
resize=${resizeArgs}
out-file-id=${epoch}`,
        job_name: `get_server_screenshot::${serverUUID}::${epoch}`,
        job_title: 'job_0356',
        job_description: 'job_0357',
        job_host_uuid: serverHostUUID,
      });
    } catch (subError) {
      stderr(`Failed to queue fetch server screenshot job; CAUSE: ${subError}`);

      response.status(500).send();

      return;
    }
  } else {
    // For getting sever detail data.

    response.status(200).send();
  }
};
