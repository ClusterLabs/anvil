import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_DOMAIN,
  REP_IPV4,
  REP_IPV4_CSV,
  REP_PEACEFUL_STRING,
  REP_UUID,
  SERVER_PATHS,
} from '../../consts';

import { getLocalHostUUID, job, variable } from '../../accessModule';
import { buildJobData } from '../../buildJobData';
import { buildNetworkConfig } from '../../fconfig';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';
import { cvar } from '../../varn';

export const configStriker: RequestHandler<
  unknown,
  InitializeStrikerResponseBody,
  Partial<InitializeStrikerForm>
> = async (request, response) => {
  const { body = {} } = request;

  poutvar(body, 'Begin initialize Striker; body=');

  const {
    adminPassword: rAdminPassword,
    domainName: rDomainName,
    hostName: rHostName,
    hostNumber: rHostNumber,
    dns: rDns,
    gateway: rGateway,
    gatewayInterface: rGatewayInterface,
    networks = [],
    organizationName: rOrganizationName,
    organizationPrefix: rOrganizationPrefix,
  } = body;

  const adminPassword = sanitize(rAdminPassword, 'string');
  const domainName = sanitize(rDomainName, 'string');
  const hostName = sanitize(rHostName, 'string');
  const hostNumber = sanitize(rHostNumber, 'number');
  const dns = sanitize(rDns, 'string');
  const gateway = sanitize(rGateway, 'string');
  const gatewayInterface = sanitize(rGatewayInterface, 'string');
  const organizationName = sanitize(rOrganizationName, 'string');
  const organizationPrefix = sanitize(rOrganizationPrefix, 'string');

  try {
    assert(
      REP_PEACEFUL_STRING.test(adminPassword),
      `Data admin password cannot contain single-quote, double-quote, slash, backslash, angle brackets, and curly brackets; got [${adminPassword}]`,
    );

    assert(
      REP_DOMAIN.test(domainName),
      `Data domain name can only contain alphanumeric, hyphen, and dot characters; got [${domainName}]`,
    );

    assert(
      REP_DOMAIN.test(hostName),
      `Data host name can only contain alphanumeric, hyphen, and dot characters; got [${hostName}]`,
    );

    assert(
      Number.isInteger(hostNumber) && hostNumber > 0,
      `Data host number can only contain digits; got [${hostNumber}]`,
    );

    assert(
      REP_IPV4_CSV.test(dns),
      `Data network DNS must be a comma separated list of valid IPv4 addresses; got [${dns}]`,
    );

    assert(
      REP_IPV4.test(gateway),
      `Data network gateway must be a valid IPv4 address; got [${gateway}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(gatewayInterface),
      `Data gateway interface must be a peaceful string; got [${gatewayInterface}]`,
    );

    assert(
      organizationName.length > 0,
      `Data organization name cannot be empty; got [${organizationName}]`,
    );

    assert(
      /^[a-z0-9]{1,5}$/.test(organizationPrefix),
      `Data organization prefix can only contain 1 to 5 lowercase alphanumeric characters; got [${organizationPrefix}]`,
    );
  } catch (assertError) {
    perr(
      `Failed to assert value when trying to initialize striker; CAUSE: ${assertError}.`,
    );

    return response.status(400).send();
  }

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

  poutvar(configData, `Config data before initiating striker config: `);

  const configEntries = Object.entries(configData);

  let jobUuid: string;

  try {
    const localHostUuid = getLocalHostUUID();

    for (const [ckey, cdetail] of configEntries) {
      const { step = 1, value } = cdetail;

      const vuuid = await variable({
        file: __filename,
        variable_default: '',
        varaible_description: '',
        variable_name: ckey,
        variable_section: `config_step${step}`,
        variable_source_uuid: localHostUuid,
        variable_source_table: 'hosts',
        variable_value: value,
      });

      assert(
        REP_UUID.test(vuuid),
        `Not a UUIDv4 post insert or update of ${ckey} with [${cdetail}]`,
      );
    }

    jobUuid = await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: buildJobData({
        entries: configEntries,
        getValue: ({ value }) => String(value),
      }),
      job_name: 'configure::network',
      job_title: 'job_0001',
      job_description: 'job_0071',
    });
  } catch (subError) {
    perr(`Failed to queue striker initialization; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(200).send({ jobUuid });
};
