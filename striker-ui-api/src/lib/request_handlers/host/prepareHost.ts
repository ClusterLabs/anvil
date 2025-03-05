import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, variable } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { Responder } from '../../Responder';
import { prepareHostRequestBodySchema } from './schemas';

export const prepareHost: RequestHandler<
  unknown,
  undefined,
  PrepareHostRequestBody
> = async (request, response) => {
  const respond = new Responder(response);

  let body: PrepareHostRequestBody;

  try {
    body = await prepareHostRequestBodySchema.validate(request.body);
  } catch (error) {
    return respond.s400('7b91b9d', `Invalid request body; CAUSE: ${error}`);
  }

  const { enterprise, host, redhat, target } = body;

  try {
    if (host.uuid) {
      // When reusing a host, reset the configured flag
      await variable({
        file: __filename,
        update_value_only: 1,
        variable_name: 'system::configured',
        variable_source_table: 'hosts',
        variable_source_uuid: host.uuid,
        variable_value: 0,
      });
    }

    let jobTitle: string;

    if (host.type === 'dr') {
      jobTitle = 'job_0021';
    } else {
      jobTitle = 'job_0020';
    }

    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['striker-initialize-host'].self,
      job_data: buildJobDataFromObject({
        enterprise_uuid: enterprise.uuid,
        host_name: host.name,
        password: host.password,
        rh_password: redhat.password,
        rh_user: redhat.user,
        ssh_port: host.ssh.port,
        target,
        type: host.type,
      }),
      job_description: 'job_0022',
      job_name: `initialize::${host.type}::${target}`,
      job_title: jobTitle,
    });
  } catch (error) {
    return respond.s500('9364318', `Failed to prepare host; CAUSE: ${error}`);
  }

  return respond.s200();
};
