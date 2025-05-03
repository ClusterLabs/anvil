import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, jobDone } from '../../accessModule';
import { linkDrFrom, unlinkDrFrom } from '../../drLink';
import { Responder } from '../../Responder';
import { updateAnvilStorageGroupRequestBodySchema } from './schemas';
import { perr } from '../../shell';

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
    `'${anvilUuid}'`,
    '--group',
    `'${existingSgName}'`,
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
          `'${newSgName}'`,
        ].join(' '),
        job_name: `storage-group::rename`,
        job_description: 'job_0536',
        job_title: 'job_0535',
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

  if (add && add.length) {
    try {
      linkDrFrom(anvilUuid, { lvmVgUuids: add });
    } catch (error) {
      return respond.s500(
        '1fa8857',
        `Failed to link DR host(s); CAUSE: ${error}`,
      );
    }

    for (const lvmVgUuid of add) {
      try {
        await job({
          file: __filename,
          job_command: [
            command,
            ...commandCommonArgs,
            '--add',
            '--member',
            `'${lvmVgUuid}'`,
          ].join(' '),
          job_name: `storage-group-member::add::${lvmVgUuid}`,
          job_description: 'job_0534',
          job_title: 'job_0533',
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

  if (remove && remove.length) {
    const jobUuids: string[] = [];

    for (const lvmVgUuid of remove) {
      let jobUuid: string;

      try {
        jobUuid = await job({
          file: __filename,
          job_command: [
            command,
            ...commandCommonArgs,
            '--remove',
            '--member',
            `'${lvmVgUuid}'`,
          ].join(' '),
          job_name: `storage-group-member::remove::${lvmVgUuid}`,
          job_description: 'job_0540',
          job_title: 'job_0539',
        });
      } catch (error) {
        return respond.s500(
          '6ada091',
          `Failed to remove member [${lvmVgUuid}] from storage group [${sgName}]; CAUSE: ${error}`,
        );
      }

      jobUuids.push(jobUuid);
    }

    jobDone(jobUuids)
      .then(async () => {
        try {
          await unlinkDrFrom(anvilUuid, { lvmVgUuids: remove });
        } catch (error) {
          perr(
            `Failed to unlink DR host(s) after removing storage group member(s) [${remove.join(
              ', ',
            )}]; CAUSE: ${error}`,
          );
        }
      })
      .catch((error) => {
        perr(
          `Failed to wait for job(s) [${jobUuids.join(
            ', ',
          )}] to complete; CAUSE: ${error}`,
        );
      });
  }

  return respond.s200();
};
