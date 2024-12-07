import { Netmask } from 'netmask';

import { REP_UUID } from './consts/REG_EXP_PATTERNS';

const buildInitRequestBody = <Values extends HostNetInitFormikExtension>(
  values: Values,
  ifaces: APINetworkInterfaceOverviewList | null,
) => {
  const { networkInit: netInit, ...restValues } = values;
  const { networks, ...restNetInit } = netInit;

  const ns = Object.values(networks);

  const requestBody = {
    ...restValues,
    ...restNetInit,
    gatewayInterface: ns.reduce<string>((previous, n) => {
      const { ip, sequence, subnetMask, type } = n;

      let subnet: Netmask;

      try {
        subnet = new Netmask(`${ip}/${subnetMask}`);
      } catch (error) {
        return previous;
      }

      if (subnet.contains(netInit.gateway)) {
        return `${type}${sequence}`;
      }

      return previous;
    }, ''),
    networks: ns.reduce<
      {
        interfaces: ({
          mac: string | undefined;
        } | null)[];
        ipAddress: string;
        sequence: string;
        subnetMask: string;
        type: string;
      }[]
    >((previous, n) => {
      const { interfaces, ip, sequence, subnetMask, type } = n;

      if (!interfaces.some((value) => REP_UUID.test(value))) {
        return previous;
      }

      previous.push({
        interfaces: interfaces.map((ifUuid) =>
          ifUuid
            ? {
                mac: ifaces?.[ifUuid]?.mac,
              }
            : null,
        ),
        ipAddress: ip,
        sequence,
        subnetMask,
        type,
      });

      return previous;
    }, []),
  };

  return requestBody;
};

export default buildInitRequestBody;
