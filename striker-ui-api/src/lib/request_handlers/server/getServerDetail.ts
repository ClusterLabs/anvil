import assert from 'assert';
import { RequestHandler } from 'express';
import { createReadStream, existsSync, rmSync, statSync } from 'fs';
import path from 'path';

import { REP_UUID } from '../../consts/REG_EXP_PATTERNS';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { dbQuery, sub } from '../../accessModule';
import { mkfifo } from '../../mkfifo';
import { sanitizeQS } from '../../sanitizeQS';

export const getServerDetail: RequestHandler = (request, response) => {
  const { serverUUID } = request.params;
  const { ss, resize } = request.query;

  const isScreenshot = sanitizeQS(ss, {
    returnType: 'boolean',
  });

  console.log(`serverUUID=[${serverUUID}],isScreenshot=[${isScreenshot}]`);

  try {
    assert(
      REP_UUID.test(serverUUID),
      `Server UUID must be a valid UUID; got [${serverUUID}]`,
    );
  } catch (assertError) {
    console.log(
      `Failed to assert value when trying to get server detail; CAUSE: ${assertError}.`,
    );

    response.status(500).send();

    return;
  }

  if (isScreenshot) {
    let requestHostUUID: string, serverHostUUID: string;

    try {
      requestHostUUID = sub('host_uuid', {
        subModuleName: 'Get',
      }).stdout;
    } catch (subError) {
      console.log(`Failed to get local host UUID; CAUSE: ${subError}`);

      response.status(500).send();

      return;
    }

    console.log(`requestHostUUID=[${requestHostUUID}]`);

    try {
      [[serverHostUUID]] = dbQuery(`
          SELECT server_host_uuid
          FROM servers
          WHERE server_uuid = '${serverUUID}';`).stdout;
    } catch (queryError) {
      console.log(`Failed to get server host UUID; CAUSE: ${queryError}`);

      response.status(500).send();

      return;
    }

    console.log(`serverHostUUID=[${serverHostUUID}]`);

    const imageFileName = `${serverUUID}_screenshot`;
    const imageFilePath = path.join(SERVER_PATHS.tmp.self, imageFileName);

    try {
      if (existsSync(imageFilePath)) {
        if (!statSync(imageFilePath).isFIFO()) {
          rmSync(imageFilePath);
          mkfifo(imageFilePath);
        }
      } else {
        mkfifo(imageFilePath);
      }

      const namedPipeReadStream = createReadStream(imageFilePath, {
        encoding: 'utf-8',
      });

      namedPipeReadStream.once('data', (data) => {
        response.status(200).send({ screenshot: data.toString().trim() });

        namedPipeReadStream.close();
      });
    } catch (prepPipeError) {
      console.log(`Failed to prepare named pipe; CAUSE: ${prepPipeError}`);

      response.status(500).send();

      return;
    }

    let resizeArgs = sanitizeQS(resize, {
      returnType: 'string',
    });

    if (!/^\d+x\d+$/.test(resizeArgs)) {
      resizeArgs = '';
    }

    try {
      sub('insert_or_update_jobs', {
        subParams: {
          file: __filename,
          line: 0,
          job_command:
            SERVER_PATHS.usr.sbin['anvil-get-server-screenshot'].self,
          job_data: `server-uuid=${serverUUID}
request-host-uuid=${requestHostUUID}
resize=${resizeArgs}`,
          job_name: `get_server_screenshot::${serverUUID}`,
          job_title: 'job_0356',
          job_description: 'job_0357',
          job_progress: 0,
          job_host_uuid: serverHostUUID,
        },
      }).stdout;
    } catch (subError) {
      console.log(
        `Failed to queue fetch server screenshot job; CAUSE: ${subError}`,
      );

      response.status(500).send();

      return;
    }
  } else {
    // For getting sever detail data.

    response.status(200).send();
  }
};
