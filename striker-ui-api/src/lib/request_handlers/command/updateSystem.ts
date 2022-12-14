import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr } from '../../shell';

export const updateSystem: RequestHandler = (request, response) => {
  try {
    job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-update-system'].self,
      job_description: 'job_0004',
      job_name: 'update::system',
      job_title: 'job_0003',
    });
  } catch (subError) {
    stderr(`Failed to initiate system update; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(204).send();
};
