import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { Responder } from '../../Responder';
import { createAnvilStorageGroupRequestBodySchema } from './schemas';

export const createAnvilStorageGroup: RequestHandler<
  undefined,
  undefined,
  CreateAnvilStorageGroupRequestBody
> = async (request, response) => {
  const respond = new Responder(response);

  const anvilUuid = response.locals.target.uuid;

  let body: CreateAnvilStorageGroupRequestBody;

  try {
    body = await createAnvilStorageGroupRequestBodySchema.validate(
      request.body,
    );
  } catch (error) {
    return respond.s400('262ac12', `Invalid request body; CAUSE: ${error}`);
  }

  const { name: storageGroupName } = body;

  // 1: create the empty storage group

  const command = SERVER_PATHS.usr.sbin['anvil-manage-storage-groups'].self;

  const commandCommonArgs: string[] = [
    '--anvil',
    `'${anvilUuid}'`,
    '--group',
    `'${storageGroupName}'`,
    '--add',
  ];

  try {
    await job({
      file: __filename,
      job_command: [command, ...commandCommonArgs].join(' '),
      job_name: `storage-group::add`,
      job_description: 'none',
      job_title: 'none',
      // DEBUG
      job_progress: 100,
    });
  } catch (error) {
    return respond.s500(
      '585a15e',
      `Failed to add empty storage group [${storageGroupName}]; CAUSE: ${error}`,
    );
  }

  const { add: lvmVgUuids } = body;

  if (!lvmVgUuids) {
    return respond.s201();
  }

  // 2: add each member to the empty storage group

  for (const lvmVgUuid of lvmVgUuids) {
    try {
      await job({
        file: __filename,
        job_command: [
          command,
          ...commandCommonArgs,
          '--member',
          `'${lvmVgUuid}'`,
        ].join(' '),
        job_name: `storage-group-member::add`,
        job_description: 'none',
        job_title: 'none',
        // DEBUG
        job_progress: 100,
      });
    } catch (error) {
      return respond.s500(
        'a38d7e1',
        `Failed to add member [${lvmVgUuid}] to storage group [${storageGroupName}]; CAUSE: ${error}`,
      );
    }
  }

  return respond.s201();
};
