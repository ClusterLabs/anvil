/**
 * @property {number} speed - Unit: mbps
 */
type NetworkInterfaceOverview = {
  device: string;
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  mac: string;
  name: string;
  order: number;
  speed: number;
  state: string;
  subnetMask: null | string;
  uuid: string;
};

type NetworkInterfaceOverviewList = Record<string, NetworkInterfaceOverview>;

type GetNetworkInterfaceParams = {
  host: string;
};
