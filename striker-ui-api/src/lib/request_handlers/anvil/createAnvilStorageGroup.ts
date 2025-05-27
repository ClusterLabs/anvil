import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { linkDrFrom } from '../../drLink';
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
      job_description: 'job_0532',
      job_name: `storage-group::add`,
      job_title: 'job_0531',
    });
  } catch (error) {
    return respond.s500(
      '585a15e',
      `Failed to add empty storage group [${storageGroupName}]; CAUSE: ${error}`,
    );
  }

  const { add: lvmVgUuids } = body;

  if (!lvmVgUuids || !lvmVgUuids.length) {
    return respond.s201();
  }

  // 2: try to link dr host(s) if we're adding vg(s) from dr host(s)

  try {
    linkDrFrom(anvilUuid, { lvmVgUuids });
  } catch (error) {
    return respond.s500(
      '0ec003b',
      `Failed to link DR host(s); CAUSE: ${error}`,
    );
  }

  // 3: add each member to the empty storage group

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
        job_description: 'job_0534',
        job_name: `storage-group-member::add::${lvmVgUuid}`,
        job_title: 'job_0533',
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
