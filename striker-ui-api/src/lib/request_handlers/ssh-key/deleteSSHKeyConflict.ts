import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { getLocalHostUUID, job, query } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { Responder } from '../../Responder';
import { deleteSshKeyConflictRequestBodySchema } from './schemas';

export const deleteSSHKeyConflict: RequestHandler<
  undefined,
  DeleteSshKeyConflictResponseBody | ResponseErrorBody,
  DeleteSshKeyConflictRequestBody
> = async (request, response) => {
  const { body } = request;

  const respond = new Responder(response);

  let sanitized: Required<DeleteSshKeyConflictRequestBody>;

  try {
    sanitized = await deleteSshKeyConflictRequestBodySchema.validate(body);
  } catch (error) {
    return respond.s400('3b7928e', `Invalid request body; CAUSE: ${error}`);
  }

  const { badKeys, badHost } = sanitized;

  let hostUuids: string[];

  try {
    const rows = await query<[string][]>(`SELECT host_uuid FROM hosts;`);

    hostUuids = rows.map(([uuid]) => uuid);
  } catch (error) {
    return respond.s500('79164ac', `Failed to get hosts; CAUSE: ${error}`);
  }

  const responseBody: DeleteSshKeyConflictResponseBody = {
    jobs: {},
  };

  let localHostUuid: string;

  try {
    localHostUuid = getLocalHostUUID();
  } catch (error) {
    return respond.s500('ee17828', String(error));
  }

  for (const key of badKeys) {
    for (const hostUuid of hostUuids) {
      // Don't start a deletion job on the bad host
      if (hostUuid === badHost.uuid) {
        continue;
      }

      try {
        const jobUuid = await job({
          file: __filename,
          job_command: SERVER_PATHS.usr.sbin['anvil-manage-keys'].self,
          job_data: buildJobDataFromObject({ bad_key: key }),
          job_description: 'job_0057',
          job_host_uuid: hostUuid,
          job_name: 'manage::broken_keys',
          job_title: 'job_0056',
        });

        responseBody.jobs[jobUuid] = {
          local: hostUuid === localHostUuid,
          uuid: jobUuid,
        };
      } catch (error) {
        return respond.s500(
          '41cea5a',
          `Failed to delete bad SSH key; CAUSE: ${error}`,
        );
      }
    }
  }

  return respond.s200(responseBody);
};
