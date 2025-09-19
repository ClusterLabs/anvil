type NetworkInterfaceSlot = {
  link: number;
  network: {
    sequence: number;
    type: string;
  };
};

/**
 * @property {number} speed - Unit: mbps
 */
type NetworkInterfaceOverview = {
  alias: string;
  device: string;
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  mac: string;
  name: string;
  order: number;
  slot?: NetworkInterfaceSlot;
  speed: number;
  state: string;
  subnetMask: null | string;
  uuid: string;
};

type NetworkInterfaceOverviewList = Record<string, NetworkInterfaceOverview>;

type GetNetworkInterfaceParams = {
  host: string;
};
