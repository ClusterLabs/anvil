import { buildNetworkLinkConfig } from './buildNetworkLinkConfig';
import { cvar } from '../varn';

export const buildNetworkConfig = (
  networks: InitializeStrikerNetworkForm[],
  {
    netconfStep = 2,
    netcountStep = 1,
  }: {
    netconfStep?: number;
    netcountStep?: number;
  } = {},
): FormConfigData => {
  const { counters: ncounts, data: cdata } = networks.reduce<{
    counters: Record<InitializeStrikerNetworkForm['type'], number>;
    data: FormConfigData;
  }>(
    (
      previous,
      { createBridge, interfaces, ipAddress, sequence, subnetMask, type },
    ) => {
      const { counters } = previous;

      counters[type] = counters[type] ? counters[type] + 1 : 1;

      const networkShortName = `${type}${sequence}`;

      previous.data = {
        ...previous.data,
        [cvar(netconfStep, `${networkShortName}_ip`)]: {
          step: netconfStep,
          value: ipAddress,
        },
        [cvar(netconfStep, `${networkShortName}_subnet_mask`)]: {
          step: netconfStep,
          value: subnetMask,
        },
        ...buildNetworkLinkConfig(networkShortName, interfaces),
      };

      if (createBridge) {
        previous.data[cvar(netconfStep, `${networkShortName}_create_bridge`)] =
          {
            step: netconfStep,
            value: createBridge,
          };
      }

      return previous;
    },
    { counters: {}, data: {} },
  );

  Object.entries(ncounts).forEach(([ntype, ncount]) => {
    cdata[cvar(netcountStep, `${ntype}_count`)] = { value: ncount };
  });

  return cdata;
};
