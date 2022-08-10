type InitializeStrikerNetworkForm = {
  interfaces: NetworkInterfaceOverview[];
  ipAddress: string;
  name: string;
  subnetMask: string;
  type: string;
};

type InitializeStrikerForm = {
  adminPassword: string;
  domainName: string;
  hostName: string;
  hostNumber: number;
  networkDNS: string;
  networkGateway: string;
  networks: InitializeStrikerNetworkForm[];
  organizationName: string;
  organizationPrefix: string;
};
