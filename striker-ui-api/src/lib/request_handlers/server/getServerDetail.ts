import assert from 'assert';
import { RequestHandler } from 'express';
import { createReadStream } from 'fs';
import path from 'path';

import { REP_UUID, SERVER_PATHS } from '../../consts';

import { getLocalHostUUID, job, query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { mkfifo, rm, stderr, stdout } from '../../shell';

const rmfifo = (path: string) => {
  try {
    rm(path);
  } catch (rmfifoError) {
    stderr(`Failed to clean up named pipe; CAUSE: ${rmfifoError}`);
  }
};

export const getServerDetail: RequestHandler<
  ServerDetailParamsDictionary,
  unknown,
  unknown,
  ServerDetailParsedQs
> = async (request, response) => {
  const {
    params: { serverUUID },
    query: { ss, resize },
  } = request;

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

    return response.status(500).send();
  }

  if (isScreenshot) {
    let requestHostUUID: string, serverHostUUID: string;

    try {
      requestHostUUID = getLocalHostUUID();
    } catch (subError) {
      stderr(String(subError));

      return response.status(500).send();
    }

    stdout(`requestHostUUID=[${requestHostUUID}]`);

    try {
      [[serverHostUUID]] = await query(`
          SELECT server_host_uuid
          FROM servers
          WHERE server_uuid = '${serverUUID}';`);
    } catch (queryError) {
      stderr(`Failed to get server host UUID; CAUSE: ${queryError}`);

      return response.status(500).send();
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

        rmfifo(imageFilePath);

        return response.status(200).send({ screenshot: imageData });
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

      rmfifo(imageFilePath);

      return response.status(500).send();
    }

    let resizeArgs = sanitize(resize, 'string');

    if (!/^\d+x\d+$/.test(resizeArgs)) {
      resizeArgs = '';
    }

    try {
      await job({
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

      return response.status(500).send();
    }
  } else {
    // For getting sever detail data.

    response.status(200).send();
  }
};
