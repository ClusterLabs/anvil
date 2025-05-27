import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, jobDone } from '../../accessModule';
import { unlinkDrFrom } from '../../drLink';
import { Responder } from '../../Responder';
import { deleteAnvilStorageGroupRequestBodySchema } from './schemas';
import { perr } from '../../shell';

export const deleteAnvilStorageGroup: RequestHandler = async (
  request,
  response,
) => {
  const respond = new Responder(response);

  const anvilUuid = response.locals.target.uuid;

  let body: DeleteAnvilStorageGroupRequestBody;

  try {
    body = await deleteAnvilStorageGroupRequestBodySchema.validate(
      request.body,
    );
  } catch (error) {
    return respond.s400('f97e85f', `Invalid request body; CAUSE: ${error}`);
  }

  const { name: storageGroupName } = body;

  const command = SERVER_PATHS.usr.sbin['anvil-manage-storage-groups'].self;

  const commandCommonArgs: string[] = [
    '--anvil',
    `'${anvilUuid}'`,
    '--group',
    `'${storageGroupName}'`,
  ];

  let jobUuid: string;

  try {
    jobUuid = await job({
      file: __filename,
      job_command: [command, ...commandCommonArgs, '--remove'].join(' '),
      job_description: 'job_0538',
      job_name: `storage-group::remove`,
      job_title: 'job_0537',
    });
  } catch (error) {
    return respond.s500(
      '0516923',
      `Failed to remove storage group [${storageGroupName}]; CAUSE: ${error}`,
    );
  }

  jobDone([jobUuid])
    .then(async () => {
      try {
        await unlinkDrFrom(anvilUuid, { sgName: storageGroupName });
      } catch (error) {
        perr(
          `Failed to unlink DR host(s) after removing storage group [${storageGroupName}]; CAUSE: ${error}`,
        );
      }
    })
    .catch((error) => {
      perr(`Failed to wait for job [${jobUuid}] to complete; CAUSE: ${error}`);
    });

  return respond.s204();
};
