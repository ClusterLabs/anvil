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

type APINetworkInterfaceSlot = {
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
type APINetworkInterfaceOverview = {
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  mac: string;
  name: string;
  order: number;
  slot?: APINetworkInterfaceSlot;
  speed: number;
  state: string;
  subnetMask: null | string;
  uuid: string;
};

type APINetworkInterfaceOverviewList = Record<
  string,
  APINetworkInterfaceOverview
>;
