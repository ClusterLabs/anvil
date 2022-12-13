import { RequestHandler } from 'express';

import { LOCAL } from '../../consts/LOCAL';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr, stdout } from '../../shell';

export const setHostInstallTarget: RequestHandler = (request, response) => {
  stdout(
    `Begin set host install target.\n${JSON.stringify(request.body, null, 2)}`,
  );

  const { isEnableInstallTarget } =
    request.body as SetHostInstallTargetRequestBody;
  const { hostUUID: rawHostUUID } = request.params as UpdateHostParams;
  const hostUUID: string | undefined =
    rawHostUUID === LOCAL ? undefined : rawHostUUID;
  const task = isEnableInstallTarget ? 'enable' : 'disable';

  try {
    job({
      file: __filename,
      job_command: `${SERVER_PATHS.usr.sbin['striker-manage-install-target'].self} --${task}`,
      job_description: 'job_0016',
      job_host_uuid: hostUUID,
      job_name: `install-target::${task}`,
      job_title: 'job_0015',
    });
  } catch (subError) {
    stderr(`Failed to ${task} install target; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(200).send();
};
