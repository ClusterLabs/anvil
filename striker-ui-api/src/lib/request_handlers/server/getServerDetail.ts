import assert from 'assert';
import { RequestHandler } from 'express';
import { ReadStream, createReadStream, writeFileSync } from 'fs';
import path from 'path';

import {
  GET_SERVER_SCREENSHOT_TIMEOUT,
  REP_UUID,
  SERVER_PATHS,
} from '../../consts';

import { getLocalHostUUID, job, query, write } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { mkfifo, rm, stderr, stdout } from '../../shell';

const rmfifo = (path: string) => {
  try {
    rm(path);
  } catch (rmfifoError) {
    stderr(`Failed to clean up FIFO; CAUSE: ${rmfifoError}`);
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

    const imageFifoName = `${serverUUID}_screenshot_${epoch}`;
    const imageFifoPath = path.join(SERVER_PATHS.tmp.self, imageFifoName);

    let fifoReadStream: ReadStream;

    try {
      mkfifo(imageFifoPath);

      fifoReadStream = createReadStream(imageFifoPath, {
        autoClose: true,
        emitClose: true,
        encoding: 'utf-8',
      });

      let imageData = '';

      fifoReadStream.once('error', (readError) => {
        stderr(`Failed to read from FIFO; CAUSE: ${readError}`);
      });

      fifoReadStream.once('close', () => {
        stdout(`On close; removing FIFO at ${imageFifoPath}.`);

        rmfifo(imageFifoPath);

        return response.status(200).send({ screenshot: imageData });
      });

      fifoReadStream.on('data', (data) => {
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
        `Failed to prepare FIFO and/or receive image data; CAUSE: ${prepPipeError}`,
      );

      rmfifo(imageFifoPath);

      return response.status(500).send();
    }

    let resizeArgs = sanitize(resize, 'string');

    if (!/^\d+x\d+$/.test(resizeArgs)) {
      resizeArgs = '';
    }

    let jobUuid: string;

    try {
      jobUuid = await job({
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

    const timeoutId: NodeJS.Timeout = setTimeout<[string, string]>(
      async (uuid, fpath) => {
        const [[isNotInProgress]]: [[number]] = await query(
          `SELECT
            CASE
              WHEN job_progress IN (0, 100)
                THEN CAST(1 AS BOOLEAN)
              ELSE CAST(0 AS BOOLEAN)
            END AS is_job_started
          FROM jobs
          WHERE job_uuid = '${uuid}';`,
        );

        if (isNotInProgress) {
          stdout(
            `Discard job ${uuid} because it's not-in-progress after timeout`,
          );

          try {
            const wcode = await write(
              `UPDATE jobs SET job_progress = 100 WHERE job_uuid = '${uuid}';`,
            );

            assert(wcode === 0, `Write exited with code ${wcode}`);

            writeFileSync(fpath, '');
          } catch (error) {
            stderr(`Failed to discard job ${uuid} on timeout; CAUSE: ${error}`);

            return response.status(500).send();
          }
        }
      },
      GET_SERVER_SCREENSHOT_TIMEOUT,
      jobUuid,
      imageFifoPath,
    );

    fifoReadStream.once('data', () => {
      stdout(`Receiving server screenshot image data; cancel timeout`);

      clearTimeout(timeoutId);
    });
  } else {
    // For getting sever detail data.

    response.status(200).send();
  }
};
