import assert from 'assert';
import { RequestHandler } from 'express';
import { readFileSync, readdirSync } from 'fs';
import path from 'path';

import { P_UUID, REP_UUID, SERVER_PATHS } from '../../consts';

import { getVncinfo } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr, pout, poutvar } from '../../shell';

type ServerSsMeta = {
  name: string;
  timestamp: number;
  uuid: string;
};

const disassembleServerSsName = (name: string): ServerSsMeta => {
  const csv = name.replace(
    new RegExp(`^server-uuid_(${P_UUID})_timestamp-(\\d+).*$`),
    '$1,$2',
  );

  const [uuid, t] = csv.split(',', 2);
  const timestamp = Number(t);

  return { name, timestamp, uuid };
};

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

  pout(`serverUUID=[${serverUuid}],isScreenshot=[${ss}]`);

  try {
    assert(
      REP_UUID.test(serverUuid),
      `Server UUID must be a valid UUID; got [${serverUuid}]`,
    );
  } catch (assertError) {
    perr(
      `Failed to assert value when trying to get server detail; CAUSE: ${assertError}.`,
    );

    return response.status(500).send();
  }

  if (ss) {
    const rsBody: ServerDetailScreenshot = { screenshot: '', timestamp: 0 };
    const ssDir = SERVER_PATHS.opt.alteeve.screenshots.self;

    let ssNames: string[];

    try {
      ssNames = readdirSync(SERVER_PATHS.opt.alteeve.screenshots.self, {
        encoding: 'utf-8',
      });
    } catch (error) {
      perr(`Failed to list server ${serverUuid} screenshots; CAUSE: ${error}`);

      return response.status(500).send();
    }

    const ssMetas = ssNames
      .reduce<ServerSsMeta[]>((previous, name) => {
        const meta = disassembleServerSsName(name);

        if (meta.uuid === serverUuid) {
          previous.push(meta);
        }

        return previous;
      }, [])
      .sort((a, b) => {
        if (a.timestamp === b.timestamp) return 0;

        return a.timestamp > b.timestamp ? 1 : -1;
      });

    const ssMetaLatest = ssMetas.pop();

    poutvar(ssMetaLatest, `Latest server screenshot: `);

    if (ssMetaLatest) {
      const { name, timestamp } = ssMetaLatest;

      const ssLatest = readFileSync(path.join(ssDir, name), {
        encoding: 'base64',
      });

      rsBody.screenshot = ssLatest;
      rsBody.timestamp = timestamp;
    }

    return response.send(rsBody);
  } else if (vnc) {
    let rsbody: ServerDetailVncInfo;

    try {
      rsbody = await getVncinfo(serverUuid);
    } catch (error) {
      perr(`Failed to get server ${serverUuid} VNC info; CAUSE: ${error}`);

      return response.status(500).send();
    }

    return response.send(rsbody);
  } else {
    // For getting sever detail data.

    response.send();
  }
};
