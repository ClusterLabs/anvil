import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { stderr } from '../../shell';

export const deleteHostConnection: RequestHandler<
  unknown,
  undefined,
  DeleteHostConnectionRequestBody
> = (request, response) => {
  const { body } = request;
  const hostUUIDs = Object.keys(body);

  hostUUIDs.forEach((key) => {
    const hostUUID = toHostUUID(key);
    const peerHostUUIDs = body[key];

    peerHostUUIDs.forEach((peerHostUUID) => {
      try {
        job({
          file: __filename,
          job_command: `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --remove --host-uuid ${peerHostUUID}`,
          job_description: 'job_0014',
          job_host_uuid: hostUUID,
          job_name: 'striker-peer::delete',
          job_title: 'job_0013',
        });
      } catch (subError) {
        stderr(`Failed to delete peer ${peerHostUUID}; CAUSE: ${subError}`);

        response.status(500).send();

        return;
      }
    });
  });

  response.status(204).send();
};
