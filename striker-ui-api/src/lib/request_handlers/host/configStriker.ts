import assert from 'assert';
import { RequestHandler } from 'express';

import {
  REP_DOMAIN,
  REP_IPV4,
  REP_IPV4_CSV,
  REP_PEACEFUL_STRING,
  SERVER_PATHS,
} from '../../consts';

import { job } from '../../accessModule';
import { sanitize } from '../../sanitize';
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

  try {
    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-configure-host'].self,
      job_data: `${fvar(1, 'domain')}=${domainName}
${fvar(1, 'organization')}=${organizationName}
${fvar(1, 'prefix')}=${organizationPrefix}
${fvar(1, 'sequence')}=${hostNumber}
${fvar(2, 'dns')}=${networkDns}
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
