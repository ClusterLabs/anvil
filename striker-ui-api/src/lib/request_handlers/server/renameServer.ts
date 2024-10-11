import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { ResponseError } from '../../ResponseError';
import {
  serverRenameRequestBodySchema,
  serverUpdateParamsDictionarySchema,
} from './schemas';
import { perr } from '../../shell';

export const renameServer: RequestHandler<
  ServerUpdateParamsDictionary,
  ServerUpdateResponseBody | ResponseErrorBody,
  ServerRenameRequestBody
> = async (request, response) => {
  const { body, params } = request;

  try {
    serverUpdateParamsDictionarySchema.validateSync(params);
  } catch (error) {
    const rserror = new ResponseError(
      '51406ae',
      `Invalid request params; CAUSE ${error}`,
    );

    perr(rserror.toString());

    return response.status(400).send(rserror.body);
  }

  try {
    serverRenameRequestBodySchema.validateSync(body);
  } catch (error) {
    const rserror = new ResponseError(
      'e49b06e',
      `Invalid request body; CAUSE ${error}`,
    );

    perr(rserror.toString());

    return response.status(400).send(rserror.body);
  }

  const { uuid: serverUuid } = params;
  const { newName } = body;

  let jobUuid: string;

  try {
    jobUuid = await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-rename-server'].self,
      job_data: buildJobDataFromObject({
        obj: {
          'new-name': newName,
          'server-uuid': serverUuid,
        },
      }),
      job_description: `Renames server ${serverUuid} and its resources`,
      job_name: `server::${serverUuid}::rename`,
      job_title: 'Anvil! rename server',
    });
  } catch (error) {
    const rserror = new ResponseError(
      '38286c1',
      `Failed to initiate server rename job; CAUSE: ${error}`,
    );

    perr(rserror.toString());

    return response.status(500).send(rserror.body);
  }

  response.status(200).send({ jobUuid });
};
