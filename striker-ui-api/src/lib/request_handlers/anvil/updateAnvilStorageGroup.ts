import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job } from '../../accessModule';
import { Responder } from '../../Responder';
import { updateAnvilStorageGroupRequestBodySchema } from './schemas';

export const updateAnvilStorageGroup: RequestHandler<
  undefined,
  undefined,
  UpdateAnvilStorageGroupRequestBody
> = async (request, response) => {
  const respond = new Responder(response);

  const anvilUuid = response.locals.target.uuid;

  let body: UpdateAnvilStorageGroupRequestBody;

  try {
    body = await updateAnvilStorageGroupRequestBodySchema.validate(
      request.body,
    );
  } catch (error) {
    return respond.s400('50c281e', `Invalid request body; CAUSE: ${error}`);
  }

  const { name: existingSgName, rename: newSgName } = body;

  const command = SERVER_PATHS.usr.sbin['anvil-manage-storage-groups'].self;

  const commandCommonArgs: string[] = [
    '--anvil',
    anvilUuid,
    '--group',
    existingSgName,
  ];

  if (newSgName) {
    try {
      await job({
        file: __filename,
        job_command: [
          command,
          ...commandCommonArgs,
          '--rename',
          '--new-name',
          newSgName,
        ].join(' '),
        job_name: `storage-group::rename`,
        job_description: 'none',
        job_title: 'none',
        // DEBUG
        job_progress: 100,
      });
    } catch (error) {
      return respond.s500(
        '1804a06',
        `Failed to rename storage group [${existingSgName}]->[${newSgName}]; CAUSE: ${error}`,
      );
    }
  }

  const sgName = newSgName || existingSgName;

  const { add } = body;

  if (add) {
    for (const lvmVgUuid of add) {
      try {
        await job({
          file: __filename,
          job_command: [
            command,
            ...commandCommonArgs,
            '--add',
            '--member',
            lvmVgUuid,
          ].join(' '),
          job_name: `storage-group-member::add::${lvmVgUuid}`,
          job_description: 'none',
          job_title: 'none',
          // DEBUG
          job_progress: 100,
        });
      } catch (error) {
        return respond.s500(
          '6ada091',
          `Failed to add member [${lvmVgUuid}] to storage group [${sgName}]; CAUSE: ${error}`,
        );
      }
    }
  }

  const { remove } = body;

  if (remove) {
    for (const lvmVgUuid of remove) {
      try {
        await job({
          file: __filename,
          job_command: [
            command,
            ...commandCommonArgs,
            '--remove',
            '--member',
            lvmVgUuid,
          ].join(' '),
          job_name: `storage-group-member::remove::${lvmVgUuid}`,
          job_description: 'none',
          job_title: 'none',
          // DEBUG
          job_progress: 100,
        });
      } catch (error) {
        return respond.s500(
          '6ada091',
          `Failed to remove member [${lvmVgUuid}] from storage group [${sgName}]; CAUSE: ${error}`,
        );
      }
    }
  }

  return respond.s200();
};
