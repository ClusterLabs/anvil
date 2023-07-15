import { cvar } from '../varn';

export const buildNetworkLinkConfig = (
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
