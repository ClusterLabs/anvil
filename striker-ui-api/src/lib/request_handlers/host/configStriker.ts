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
import { sanitize } from '../../sanitize';
import { stderr, stdoutVar } from '../../shell';

const cvar = (configStepCount: number, fieldName: string) =>
  ['form', `config_step${configStepCount}`, fieldName, 'value'].join('::');

const buildNetworkLinkConfigs = (
  networkShortName: string,
  interfaces: InitializeStrikerNetworkForm['interfaces'],
  configStep = 2,
) =>
  interfaces.reduce<FormConfigData>((previous, iface, index) => {
    if (iface) {
      const { networkInterfaceMACAddress } = iface;
      const linkNumber = index + 1;

      previous[
        cvar(configStep, `${networkShortName}_link${linkNumber}_mac_to_set`)
      ] = { step: configStep, value: networkInterfaceMACAddress };
    }

    return previous;
  }, {});

const buildNetworkConfigs = (
  networks: InitializeStrikerNetworkForm[],
  configStep = 2,
): FormConfigData => {
  const { counters: ncounts, data: cdata } = networks.reduce<{
    counters: Record<InitializeStrikerNetworkForm['type'], number>;
    data: FormConfigData;
  }>(
    (previous, { interfaces, ipAddress, subnetMask, type }) => {
      const { counters } = previous;

      counters[type] = counters[type] ? counters[type] + 1 : 1;

      const networkShortName = `${type}${counters[type]}`;

      previous.data = {
        ...previous.data,
        [cvar(configStep, `${networkShortName}_ip`)]: {
          step: configStep,
          value: ipAddress,
        },
        [cvar(configStep, `${networkShortName}_subnet_mask`)]: {
          step: configStep,
          value: subnetMask,
        },
        ...buildNetworkLinkConfigs(networkShortName, interfaces),
      };

      return previous;
    },
    { counters: {}, data: {} },
  );

  Object.entries(ncounts).forEach(([ntype, ncount]) => {
    cdata[cvar(1, `${ntype}_count`)] = { value: ncount };
  });

  return cdata;
};

const configToJobData = (
  entries: [keyof FormConfigData, FormConfigData[keyof FormConfigData]][],
) =>
  entries
    .reduce<string>((previous, [key, value]) => {
      previous += `${key}=${value}\n`;

      return previous;
    }, '')
    .trim();

export const configStriker: RequestHandler<
  unknown,
  undefined,
  Partial<InitializeStrikerForm>
> = async (request, response) => {
  const { body = {} } = request;

  stdoutVar(body, 'Begin initialize Striker; body=');

  const {
    adminPassword: rAdminPassword = '',
    domainName: rDomainName = '',
    hostName: rHostName = '',
    hostNumber: rHostNumber = 0,
    networkDNS: rNetworkDns = '',
    networkGateway: rNetworkGateway = '',
    networks = [],
    organizationName: rOrganizationName = '',
    organizationPrefix: rOrganizationPrefix = '',
  } = body;

  const adminPassword = sanitize(rAdminPassword, 'string');
  const domainName = sanitize(rDomainName, 'string');
  const hostName = sanitize(rHostName, 'string');
  const hostNumber = sanitize(rHostNumber, 'number');
  const networkDns = sanitize(rNetworkDns, 'string');
  const networkGateway = sanitize(rNetworkGateway, 'string');
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
      REP_IPV4_CSV.test(networkDns),
      `Data network DNS must be a comma separated list of valid IPv4 addresses; got [${networkDns}]`,
    );

    assert(
      REP_IPV4.test(networkGateway),
      `Data network gateway must be a valid IPv4 address; got [${networkGateway}]`,
    );

    assert(
      REP_PEACEFUL_STRING.test(organizationName),
      `Data organization name cannot be empty; got [${organizationName}]`,
    );

    assert(
      /^[a-z0-9]{1,5}$/.test(organizationPrefix),
      `Data organization prefix can only contain 1 to 5 lowercase alphanumeric characters; got [${organizationPrefix}]`,
    );
  } catch (assertError) {
    stderr(
      `Failed to assert value when trying to initialize striker; CAUSE: ${assertError}.`,
    );

    return response.status(400).send();
  }

  const configData: FormConfigData = {
    [cvar(1, 'domain')]: { value: domainName },
    [cvar(1, 'organization')]: { value: organizationName },
    [cvar(1, 'prefix')]: { value: organizationPrefix },
    [cvar(1, 'sequence')]: { value: hostNumber },
    [cvar(2, 'dns')]: { step: 2, value: networkDns },
    [cvar(2, 'gateway')]: { step: 2, value: networkGateway },
    [cvar(2, 'host_name')]: { step: 2, value: hostName },
    [cvar(2, 'striker_password')]: { step: 2, value: adminPassword },
    [cvar(2, 'striker_user')]: { step: 2, value: 'admin' },
    ...buildNetworkConfigs(networks),
  };

  stdoutVar(configData, `Config data before initiating striker config: `);

  const configEntries = Object.entries(configData);

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

    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: configToJobData(configEntries),
      job_name: 'configure::network',
      job_title: 'job_0001',
      job_description: 'job_0071',
    });
  } catch (subError) {
    stderr(`Failed to queue striker initialization; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(200).send();
};
