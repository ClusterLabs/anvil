import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { perr } from '../../shell';

export const deleteSSHKeyConflict: RequestHandler<
  unknown,
  undefined,
  DeleteSshKeyConflictRequestBody
> = async (request, response) => {
  const { body } = request;
  const hostUuids = Object.keys(body);

  for (const uuid of hostUuids) {
    const hostUuid = toHostUUID(uuid);
    const stateUuids = body[uuid];

    try {
      await job({
        file: __filename,
        job_command: SERVER_PATHS.usr.sbin['anvil-manage-keys'].self,
        job_data: stateUuids.join(','),
        job_description: 'job_0057',
        job_host_uuid: hostUuid,
        job_name: 'manage::broken_keys',
        job_title: 'job_0056',
      });
    } catch (subError) {
      perr(`Failed to delete bad SSH keys; CAUSE: ${subError}`);

      return response.status(500).send();
    }
  }

  response.status(204).send();
};
