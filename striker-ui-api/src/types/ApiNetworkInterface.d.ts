type NetworkInterfaceOverview = {
  dns: null | string;
  gateway: null | string;
  ip: null | string;
  mac: string;
  name: string;
  order: number;
  // Unit: Mbps
  speed: number;
  state: string;
  subnetMask: null | string;
  uuid: string;
};

type NetworkInterfaceOverviewList = Record<string, NetworkInterfaceOverview>;
