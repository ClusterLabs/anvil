import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { getLocalHostUUID, job } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { buildNetworkConfig } from '../../fconfig';
import { Responder } from '../../Responder';
import { configStrikerRequestBodySchema } from './schemas';
import { setConfigVariables } from './setConfigVariables';
import { poutvar } from '../../shell';
import { cvar } from '../../varn';

export const configStriker: RequestHandler<
  unknown,
  InitializeStrikerResponseBody,
  InitializeStrikerForm
> = async (request, response) => {
  const respond = new Responder(response);

  let body: InitializeStrikerForm;

  try {
    body = await configStrikerRequestBodySchema.validate(request.body);
  } catch (error) {
    return respond.s400('88d8673', `Invalid request body; CAUSE: ${error}`);
  }

  const {
    adminPassword,
    domainName,
    hostName,
    hostNumber,
    dns,
    gateway,
    gatewayInterface,
    networks,
    organizationName,
    organizationPrefix,
  } = body;

  const configData: FormConfigData = {
    [cvar(1, 'domain')]: { value: domainName },
    [cvar(1, 'organization')]: { value: organizationName },
    [cvar(1, 'prefix')]: { value: organizationPrefix },
    [cvar(1, 'sequence')]: { value: hostNumber },
    [cvar(2, 'dns')]: { step: 2, value: dns },
    [cvar(2, 'gateway')]: { step: 2, value: gateway },
    [cvar(2, 'gateway_interface')]: { step: 2, value: gatewayInterface },
    [cvar(2, 'host_name')]: { step: 2, value: hostName },
    [cvar(2, 'striker_password')]: { step: 2, value: adminPassword },
    [cvar(2, 'striker_user')]: { step: 2, value: 'admin' },
    ...buildNetworkConfig(networks),
  };

  poutvar(configData, `Config striker with data: `);

  let jobUuid: string;

  try {
    const localHostUuid = getLocalHostUUID();

    await setConfigVariables(configData, localHostUuid);

    jobUuid = await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: buildJobDataFromObject(configData),
      job_name: 'configure::network',
      job_title: 'job_0001',
      job_description: 'job_0071',
    });
  } catch (error) {
    return respond.s500(
      'd864d78',
      `Failed to register striker config job; CAUSE: ${error}`,
    );
  }

  return respond.s200({
    jobUuid,
  });
};
