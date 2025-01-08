import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { perr } from '../../shell';

export const updateSystem: RequestHandler = async (request, response) => {
  try {
    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-update-system'].self,
      job_description: 'job_0528',
      job_name: 'update::system',
      job_title: 'job_0527',
    });
  } catch (subError) {
    perr(`Failed to initiate system update; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(204).send();
};
