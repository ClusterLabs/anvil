import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { stderr } from '../../shell';

export const deleteHostConnection: RequestHandler<
  unknown,
  undefined,
  DeleteHostConnectionRequestBody
> = async (request, response) => {
  const { body } = request;
  const hostUuids = Object.keys(body);

  for (const key of hostUuids) {
    const hostUuid = toHostUUID(key);
    const peerHostUuids = body[key];

    for (const peerHostUuid of peerHostUuids) {
      try {
        await job({
          file: __filename,
          job_command: `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --remove --host-uuid ${peerHostUuid}`,
          job_description: 'job_0014',
          job_host_uuid: hostUuid,
          job_name: 'striker-peer::delete',
          job_title: 'job_0013',
        });
      } catch (subError) {
        stderr(`Failed to delete peer ${peerHostUuid}; CAUSE: ${subError}`);

        return response.status(500).send();
      }
    }
  }

  response.status(204).send();
};
