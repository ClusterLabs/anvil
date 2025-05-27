import assert from 'assert';
import { RequestHandler } from 'express';

import { SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { buildNetworkConfig } from '../../fconfig';
import { Responder } from '../../Responder';
import {
  prepareNetworkParamsSchema,
  prepareNetworkRequestBodySchema,
} from './schemas';
import { setConfigVariables } from './setConfigVariables';
import { poutvar } from '../../shell';
import { cvar } from '../../varn';

export const prepareNetwork: RequestHandler<
  UpdateHostParams,
  undefined,
  PrepareNetworkRequestBody
> = async (request, response) => {
  const respond = new Responder(response);

  let params: UpdateHostParams;

  try {
    params = await prepareNetworkParamsSchema.validate(request.params);
  } catch (error) {
    return respond.s400('b06b9a0', `Invalid query params; CAUSE: ${error}`);
  }

  let body: PrepareNetworkRequestBody;

  try {
    body = await prepareNetworkRequestBodySchema.validate(request.body);
  } catch (error) {
    return respond.s400('715ebab', `Invalid request body; CAUSE: ${error}`);
  }

  const { hostUUID: hostUuid } = params;

  const { dns, gateway, gatewayInterface, hostName, networks, ntp } = body;

  let hostType: string;

  try {
    const rows = await query<[[string]]>(
      `SELECT host_type FROM hosts WHERE host_uuid = '${hostUuid}';`,
    );

    assert.ok(rows.length, `No record found`);

    [[hostType]] = rows;
  } catch (error) {
    return respond.s500(
      '2406ad3',
      `Failed to get host type with ${hostUuid}; CAUSE: ${error}`,
    );
  }

  networks.forEach((network) => {
    const { interfaces: ifaces, type } = network;

    if (
      hostType === 'node' &&
      ['bcn', 'ifn'].includes(type) &&
      ifaces.length === 2 &&
      !ifaces.some((iface) => !iface)
    ) {
      network.createBridge = '1';
    }
  });

  const configData: FormConfigData = {
    [cvar(2, 'dns')]: { step: 2, value: dns },
    [cvar(2, 'gateway')]: { step: 2, value: gateway },
    [cvar(2, 'gateway_interface')]: { step: 2, value: gatewayInterface },
    [cvar(2, 'host_name')]: { step: 2, value: hostName },
    ...buildNetworkConfig(networks),
    'network::ntp::servers': { step: 2, value: ntp },
  };

  poutvar(configData, `Prepare network on host ${hostUuid} with data: `);

  try {
    await setConfigVariables(configData, hostUuid);

    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: buildJobDataFromObject(configData, {
        getValue: ({ value }) => String(value),
      }),
      job_host_uuid: hostUuid,
      job_name: 'configure::network',
      job_title: 'job_0001',
      job_description: 'job_0071',
    });
  } catch (error) {
    return respond.s500(
      'f3d5c72',
      `Failed to queue prepare network; CAUSE: ${error}`,
    );
  }

  return respond.s200();
};
