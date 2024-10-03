/**
 * @deprecated
 */
type NetworkInterfaceOverviewMetadata = {
  networkInterfaceUUID: string;
  networkInterfaceMACAddress: string;
  networkInterfaceName: string;
  networkInterfaceState: string;
  networkInterfaceSpeed: number;
  networkInterfaceOrder: number;
};

type APINetworkInterfaceOverview = {
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  mac: string;
  name: string;
  order: number;
  // Unit: mbps
  speed: number;
  state: string;
  subnetMask: null | string;
  uuid: string;
};

type APINetworkInterfaceOverviewList = {
  [uuid: string]: APINetworkInterfaceOverview;
};
