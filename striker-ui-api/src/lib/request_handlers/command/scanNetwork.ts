import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { Responder } from '../../Responder';

export const scanNetwork: RequestHandler<
  undefined,
  RegisteredJob | ResponseErrorBody
> = async (request, response) => {
  const respond = new Responder(response);

  const registered: RegisteredJob = {
    uuid: '',
  };

  try {
    registered.uuid = await job({
      file: __filename,
      job_command: `${SERVER_PATHS.usr.sbin['striker-scan-network'].self} --log-secure`,
      job_description: 'job_0067',
      job_name: 'scan-network::refresh',
      job_title: 'job_0066',
    });
  } catch (error) {
    return respond.s500(
      '02552f5',
      `Failed to register network scan; CASUE: ${error}`,
    );
  }

  return respond.s200(registered);
};
