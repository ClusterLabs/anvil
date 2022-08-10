import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { sub } from '../../accessModule';

const fvar = (configStepCount: number, fieldName: string) =>
  ['form', `config_step${configStepCount}`, fieldName, 'value'].join('::');

const buildNetworkLinks = (
  configStepCount: number,
  networkShortName: string,
  interfaces: NetworkInterfaceOverview[],
) =>
  interfaces.reduce<string>(
    (reduceContainer, { networkInterfaceMACAddress }, index) =>
      `${reduceContainer}
${fvar(
  configStepCount,
  `${networkShortName}_link${index + 1}_mac_to_set`,
)}=${networkInterfaceMACAddress}`,
    '',
  );

export const initializeStriker: RequestHandler<
  unknown,
  undefined,
  InitializeStrikerForm
> = (request, response) => {
  console.log('Begin initialize Striker.');
  console.dir(request.body);

  const {
    body: {
      adminPassword,
      domainName,
      hostName,
      hostNumber,
      networkDNS,
      networkGateway,
      networks,
      organizationName,
      organizationPrefix,
    },
  } = request;

  try {
    sub('insert_or_update_jobs', {
      subParams: {
        file: __filename,
        line: 0,
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
        job_progress: 0,
      },
    }).stdout;
  } catch (subError) {
    console.log(
      `Failed to queue fetch server screenshot job; CAUSE: ${subError}`,
    );

    response.status(500).send();

    return;
  }

  response.status(200).send();
};
