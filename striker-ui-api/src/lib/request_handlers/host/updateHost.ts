import { RequestHandler } from 'express';

import { LOCAL } from '../../consts/LOCAL';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stdout } from '../../shell';

export const updateHost: RequestHandler<
  { hostUUID: string },
  undefined,
  { isEnableInstallTarget?: boolean }
> = (request, response) => {
  stdout(
    `Begin edit host properties.\n${JSON.stringify(request.body, null, 2)}`,
  );

  const {
    body: { isEnableInstallTarget },
    params: { hostUUID: rawHostUUID },
  } = request;
  const hostUUID: string | undefined =
    rawHostUUID === LOCAL ? undefined : rawHostUUID;

  if (isEnableInstallTarget !== undefined) {
    const task = isEnableInstallTarget ? 'enable' : 'disable';

    job({
      file: __filename,
      job_command: `${SERVER_PATHS.usr.sbin['striker-manage-install-target'].self} --${task}`,
      job_description: 'job_0016',
      job_host_uuid: hostUUID,
      job_name: `install-target::${task}`,
      job_title: 'job_0015',
    });
  }

  response.status(200).send();
};
