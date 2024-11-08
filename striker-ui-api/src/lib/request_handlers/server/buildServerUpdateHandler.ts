import assert from 'assert';
import { Request, RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { Responder } from '../../Responder';
import { serverUpdateParamsDictionarySchema } from './schemas';
import { perr } from '../../shell';

type P = ServerUpdateParamsDictionary;
type ResBody = ServerUpdateResponseBody | ResponseErrorBody;

type S = {
  host: {
    uuid: string;
  };
  name: string;
};

export const buildServerUpdateHandler =
  <
    ReqBody = Express.RhReqBody,
    ReqQuery = Express.RhReqQuery,
    Locals extends Express.RhLocals = Express.RhLocals,
  >(
    validate: (
      request: Request<P, ResBody, ReqBody, ReqQuery, Locals>,
    ) => Promise<void>,
    buildJobParams: (
      request: Request<P, ResBody, ReqBody, ReqQuery, Locals>,
      server: S,
      sbin: Readonly<FilledServerPath>,
    ) => Promise<Omit<JobParams, 'file'>>,
  ): RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals> =>
  async (request, response) => {
    const { params } = request;

    const respond = new Responder<ResBody, Locals>(response);

    try {
      serverUpdateParamsDictionarySchema.validateSync(params);

      await validate(request);
    } catch (error) {
      return respond.s400('e49b06e', `Invalid request; CAUSE ${error}`);
    }

    const { uuid: serverUuid } = params;

    const server = {
      host: {
        uuid: '',
      },
      name: '',
    };

    try {
      const rows = await query<[[string, string]]>(
        `SELECT
            server_name,
            server_host_uuid
          FROM servers
          WHERE server_uuid = '${serverUuid}';`,
      );

      assert.ok(rows.length, 'No record found');

      [[server.name, server.host.uuid]] = rows;
    } catch (error) {
      perr(`Failed to get server host; CAUSE: ${error}`);
    }

    const jobParams: JobParams = {
      file: __filename,

      ...(await buildJobParams(request, server, SERVER_PATHS.usr.sbin)),
    };

    let jobUuid: string;

    try {
      jobUuid = await job(jobParams);
    } catch (error) {
      return respond.s500(
        '38286c1',
        `Failed to update server job; CAUSE: ${error}`,
      );
    }

    return respond.s200({ jobUuid });
  };
