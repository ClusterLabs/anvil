type NetworkInterfaceSlot = {
  alias: string;
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  link: number;
  sequence: number;
  subnetMask: null | string;
  type: string;
};

/**
 * @property {number} speed - Unit: mbps
 */
type NetworkInterfaceOverview = {
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
