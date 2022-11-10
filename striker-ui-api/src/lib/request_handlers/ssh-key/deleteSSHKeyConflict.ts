import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr } from '../../shell';

export const deleteSSHKeyConflict: RequestHandler<
  unknown,
  undefined,
  DeleteSSHKeyConflictRequestBody
> = (request, response) => {
  const { body } = request;
  const hostUUIDs = Object.keys(body);

  hostUUIDs.forEach((hostUUID) => {
    const stateUUIDs = body[hostUUID];

    try {
      job({
        file: __filename,
        job_command: SERVER_PATHS.usr.sbin['anvil-manage-keys'].self,
        job_data: stateUUIDs.join(','),
        job_description: 'job_0057',
        job_host_uuid: hostUUID,
        job_name: 'manage::broken_keys',
        job_title: 'job_0056',
      });
    } catch (subError) {
      stderr(`Failed to delete bad SSH keys; CAUSE: ${subError}`);

      response.status(500).send();

      return;
    }
  });

  response.status(204).send();
};
