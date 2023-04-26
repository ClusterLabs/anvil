import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_DOMAIN,
  REP_INTEGER,
  REP_IPV4,
  REP_IPV4_CSV,
} from '../../consts/REG_EXP_PATTERNS';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr, stdoutVar } from '../../shell';

const fvar = (configStepCount: number, fieldName: string) =>
  ['form', `config_step${configStepCount}`, fieldName, 'value'].join('::');

const buildNetworkLinks = (
  configStepCount: number,
  networkShortName: string,
  interfaces: InitializeStrikerNetworkForm['interfaces'],
) =>
  interfaces.reduce<string>((reduceContainer, iface, index) => {
    let result = reduceContainer;

    if (iface) {
      const { networkInterfaceMACAddress } = iface;

      result += `
${fvar(
  configStepCount,
  `${networkShortName}_link${index + 1}_mac_to_set`,
)}=${networkInterfaceMACAddress}`;
    }

    return result;
  }, '');

export const configStriker: RequestHandler<
  unknown,
  undefined,
  InitializeStrikerForm
> = ({ body }, response) => {
  stdoutVar(body, 'Begin initialize Striker; body=');

  const {
    adminPassword = '',
    domainName = '',
    hostName = '',
    hostNumber = 0,
    networkDNS = '',
    networkGateway = '',
    networks = [],
    organizationName = '',
    organizationPrefix = '',
  } = body || {};

  const dataAdminPassword = String(adminPassword);
  const dataDomainName = String(domainName);
  const dataHostName = String(hostName);
  const dataHostNumber = String(hostNumber);
  const dataNetworkDNS = String(networkDNS);
  const dataNetworkGateway = String(networkGateway);
  const dataOrganizationName = String(organizationName);
  const dataOrganizationPrefix = String(organizationPrefix);

  try {
    assert(
      !/['"/\\><}{]/g.test(dataAdminPassword),
      `Data admin password cannot contain single-quote, double-quote, slash, backslash, angle brackets, and curly brackets; got [${dataAdminPassword}]`,
    );

    assert(
      REP_DOMAIN.test(dataDomainName),
      `Data domain name can only contain alphanumeric, hyphen, and dot characters; got [${dataDomainName}]`,
    );

    assert(
      REP_DOMAIN.test(dataHostName),
      `Data host name can only contain alphanumeric, hyphen, and dot characters; got [${dataHostName}]`,
    );

    assert(
      REP_INTEGER.test(dataHostNumber) && hostNumber > 0,
      `Data host number can only contain digits; got [${dataHostNumber}]`,
    );

    assert(
      REP_IPV4_CSV.test(dataNetworkDNS),
      `Data network DNS must be a comma separated list of valid IPv4 addresses; got [${dataNetworkDNS}]`,
    );

    assert(
      REP_IPV4.test(dataNetworkGateway),
      `Data network gateway must be a valid IPv4 address; got [${dataNetworkGateway}]`,
    );

    assert(
      dataOrganizationName.length > 0,
      `Data organization name cannot be empty; got [${dataOrganizationName}]`,
    );

    assert(
      /^[a-z0-9]{1,5}$/.test(dataOrganizationPrefix),
      `Data organization prefix can only contain 1 to 5 lowercase alphanumeric characters; got [${dataOrganizationPrefix}]`,
    );
  } catch (assertError) {
    stderr(
      `Failed to assert value when trying to initialize striker; CAUSE: ${assertError}.`,
    );

    return response.status(400).send();
  }

  try {
    job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: `${fvar(1, 'domain')}=${domainName}
${fvar(1, 'organization')}=${organizationName}
${fvar(1, 'prefix')}=${organizationPrefix}
${fvar(1, 'sequence')}=${hostNumber}
${fvar(2, 'dns')}=${networkDNS}
${fvar(2, 'gateway')}=${networkGateway}
${fvar(2, 'host_name')}=${hostName}
${fvar(2, 'striker_password')}=${adminPassword}
${fvar(2, 'striker_user')}=admin${
        networks.reduce<{
          counters: Record<InitializeStrikerNetworkForm['type'], number>;
          result: string;
        }>(
          (reduceContainer, { interfaces, ipAddress, subnetMask, type }) => {
            const { counters } = reduceContainer;

            counters[type] = counters[type] ? counters[type] + 1 : 1;

            const networkShortName = `${type}${counters[type]}`;

            reduceContainer.result += `
${fvar(2, `${networkShortName}_ip`)}=${ipAddress}
${fvar(2, `${networkShortName}_subnet_mask`)}=${subnetMask}
${buildNetworkLinks(2, networkShortName, interfaces)}`;

            return reduceContainer;
          },
          { counters: {}, result: '' },
        ).result
      }`,
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
