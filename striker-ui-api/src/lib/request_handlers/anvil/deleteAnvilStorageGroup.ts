import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { Responder } from '../../Responder';
import { deleteAnvilStorageGroupRequestBodySchema } from './schemas';

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

  try {
    await job({
      file: __filename,
      job_command: [command, ...commandCommonArgs, '--remove'].join(' '),
      job_name: `storage-group::remove`,
      job_description: 'none',
      job_title: 'none',
      // DEBUG
      job_progress: 100,
    });
  } catch (error) {
    return respond.s500(
      '0516923',
      `Failed to remove storage group [${storageGroupName}]; CAUSE: ${error}`,
    );
  }

  return respond.s204();
};
