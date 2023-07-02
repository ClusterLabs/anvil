import { buildNetworkLinkConfig } from './buildNetworkLinkConfig';
import { cvar } from '../varn';

export const buildNetworkConfig = (
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
        ...buildNetworkLinkConfig(networkShortName, interfaces),
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
