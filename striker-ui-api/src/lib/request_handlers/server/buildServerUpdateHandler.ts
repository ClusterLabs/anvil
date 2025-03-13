import assert from 'assert';
import { Request, RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { Responder } from '../../Responder';
import { perr } from '../../shell';

type P = RequestTarget;
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
    Locals extends LocalsRequestTarget = LocalsRequestTarget,
  >(
    validate:
      | ((
          request: Request<P, ResBody, ReqBody, ReqQuery, Locals>,
        ) => Promise<void>)
      | null
      | undefined,
    buildJobParams: (
      request: Request<P, ResBody, ReqBody, ReqQuery, Locals>,
      server: S,
      sbin: Readonly<FilledServerPath>,
    ) => Promise<Omit<JobParams, 'file'>>,
  ): RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals> =>
  async (request, response) => {
    const respond = new Responder<ResBody, Locals>(response);

    try {
      await validate?.call(null, request);
    } catch (error) {
      return respond.s400('e49b06e', `Invalid request; CAUSE ${error}`);
    }

    const { uuid: serverUuid } = response.locals.target;

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

    let jobParams: JobParams;

    try {
      jobParams = {
        file: __filename,

        ...(await buildJobParams(request, server, SERVER_PATHS.usr.sbin)),
      };
    } catch (error) {
      return respond.s500(
        '3028429',
        `Failed to build job params; CAUSE: ${error}`,
      );
    }

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
