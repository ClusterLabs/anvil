import { cvar } from '../varn';

export const buildNetworkLinkConfig = (
  short: string,
  interfaces: InitializeStrikerNetworkForm['interfaces'],
  step = 2,
) =>
  interfaces.reduce<FormConfigData>((previous, iface, index) => {
    if (!iface) {
      return previous;
    }

    const link = index + 1;

    previous[cvar(step, `${short}_link${link}_mac_to_set`)] = {
      step,
      value: iface.mac,
    };

    return previous;
  }, {});
