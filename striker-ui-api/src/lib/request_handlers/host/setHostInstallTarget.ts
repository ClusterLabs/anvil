import { RequestHandler } from 'express';

import { LOCAL } from '../../consts/LOCAL';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { perr, poutvar } from '../../shell';

export const setHostInstallTarget: RequestHandler<
  UpdateHostParams,
  undefined,
  SetHostInstallTargetRequestBody
> = async (request, response) => {
  const { body, params } = request;

  poutvar(body, `Begin set host install target; body=`);

  const { isEnableInstallTarget } = body;
  const { hostUUID: rHostUuid } = params;

  const hostUuid: string | undefined =
    rHostUuid === LOCAL ? undefined : rHostUuid;
  const task = isEnableInstallTarget ? 'enable' : 'disable';

  try {
    await job({
      file: __filename,
      job_command: `${SERVER_PATHS.usr.sbin['striker-manage-install-target'].self} --${task}`,
      job_description: 'job_0526',
      job_host_uuid: hostUuid,
      job_name: `install-target::${task}`,
      job_title: 'job_0525',
    });
  } catch (subError) {
    perr(`Failed to ${task} install target; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(204).send();
};
