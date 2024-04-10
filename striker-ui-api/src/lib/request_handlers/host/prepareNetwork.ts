import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_IPV4,
  REP_IPV4_CSV,
  REP_PEACEFUL_STRING,
  REP_UUID,
  SERVER_PATHS,
} from '../../consts';

import { job, query, variable } from '../../accessModule';
import { buildJobData } from '../../buildJobData';
import { buildNetworkConfig } from '../../fconfig';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';
import { cvar } from '../../varn';

export const prepareNetwork: RequestHandler<
  UpdateHostParams,
  undefined,
  PrepareNetworkRequestBody
> = async (request, response) => {
  const {
    body: {
      dns: rDns,
      gateway: rGateway,
      hostName: rHostName,
      gatewayInterface: rGatewayInterface,
      networks = [],
    } = {},
    params: { hostUUID },
  } = request;

  const dns = sanitize(rDns, 'string');
  const gateway = sanitize(rGateway, 'string');
  const hostName = sanitize(rHostName, 'string');
  const gatewayInterface = sanitize(rGatewayInterface, 'string');

  try {
    assert(
      REP_UUID.test(hostUUID),
      `Host UUID must be a valid UUIDv4; got [${hostUUID}]`,
    );

    assert(
      REP_IPV4_CSV.test(dns),
      `DNS must be a valid IPv4 CSV; got [${dns}]`,
    );

    assert(
      REP_IPV4.test(gateway),
      `Gateway must be a valid IPv4; got [${gateway}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(hostName),
      `Host name must be a peaceful string; got [${hostName}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(gatewayInterface),
      `Gateway interface must be a peaceful string; got [${gatewayInterface}]`,
    );
  } catch (error) {
    perr(`Failed to assert value when prepare network; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let hostType: string;

  try {
    const rows = await query<[[string]]>(
      `SELECT host_type FROM hosts WHERE host_uuid = '${hostUUID}';`,
    );

    assert.ok(rows.length, `No record found`);

    [[hostType]] = rows;
  } catch (error) {
    perr(`Failed to get host type with ${hostUUID}; CAUSE: ${error}`);

    return response.status(500).send();
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
  };

  poutvar(
    configData,
    `Config data before prepare network on host ${hostUUID}: `,
  );

  const configEntries = Object.entries(configData);

  try {
    for (const [ckey, cdetail] of configEntries) {
      const { step = 1, value } = cdetail;

      const vuuid = await variable({
        file: __filename,
        variable_default: '',
        varaible_description: '',
        variable_name: ckey,
        variable_section: `config_step${step}`,
        variable_source_uuid: hostUUID,
        variable_source_table: 'hosts',
        variable_value: value,
      });

      assert(
        REP_UUID.test(vuuid),
        `Not a UUIDv4 post insert or update of ${ckey} with [${cdetail}]`,
      );
    }

    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: buildJobData({
        entries: configEntries,
        getValue: ({ value }) => String(value),
      }),
      job_host_uuid: hostUUID,
      job_name: 'configure::network',
      job_title: 'job_0001',
      job_description: 'job_0071',
    });
  } catch (error) {
    perr(`Failed to queue prepare network; CAUSE: ${error}`);

    return response.status(500).send();
  }

  return response.send();
};
