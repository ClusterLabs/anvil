type CreateHostConnectionRequestBody = {
  dbName?: string;
  ipAddress: string;
  isPing?: boolean;
  /** Host password; same as database password */
  password: string;
  port?: number;
  sshPort?: number;
  /** Database user */
  user?: string;
};

type DeleteHostConnectionRequestBody = {
  [hostUUID: string]: string[];
};

type HostConnectionOverview = {
  inbound: {
    ipAddress: {
      [ipAddress: string]: {
        hostUUID: string;
        ipAddress: string;
        ipAddressUUID: string;
        networkLinkNumber: number;
        networkNumber: number;
        networkType: string;
      };
    };
    port: number;
    user: string;
  };
  peer: {
    [ipAddress: string]: {
      hostUUID: string;
      ipAddress: string;
      isPing: boolean;
      port: number;
      user: string;
    };
  };
};

type HostOverview = {
  hostName: string;
  hostType: string;
  hostUUID: string;
  shortHostName: string;
};

type InitializeStrikerNetworkForm = {
  interfaces: Array<NetworkInterfaceOverview | null | undefined>;
  ipAddress: string;
  name: string;
  subnetMask: string;
  type: string;
};

type InitializeStrikerForm = {
  adminPassword: string;
  dns: string;
  domainName: string;
  gateway: string;
  gatewayInterface: string;
  hostName: string;
  hostNumber: number;
  networks: InitializeStrikerNetworkForm[];
  organizationName: string;
  organizationPrefix: string;
};

type PrepareHostRequestBody = {
  enterpriseUUID?: string;
  hostIPAddress: string;
  hostName: string;
  hostPassword: string;
  hostSSHPort?: number;
  hostType: string;
  hostUser?: string;
  hostUUID?: string;
  redhatPassword: string;
  redhatUser: string;
};

type PrepareNetworkRequestBody = {
  dns: string;
  gateway: string;
  gatewayInterface: string;
  hostName: string;
  networks: InitializeStrikerNetworkForm[];
};

type SetHostInstallTargetRequestBody = {
  isEnableInstallTarget: boolean;
};

type UpdateHostParams = {
  hostUUID: string;
};
