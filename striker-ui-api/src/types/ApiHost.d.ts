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
        ifaceId: string;
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

type HostIpmi = {
  command: string;
  ip: string;
  password: string;
  username: string;
};

type HostOverview = {
  anvil?: {
    name: string;
    uuid: string;
  };
  hostConfigured: boolean;
  hostName: string;
  hostStatus: string;
  hostType: string;
  hostUUID: string;
  shortHostName: string;
};

type HostDetail = HostOverview & {
  ipmi: HostIpmi;
} & Tree<string>;

type InitializeStrikerNetworkForm = {
  createBridge?: StringBoolean;
  interfaces: Array<NetworkInterfaceOverview | null | undefined>;
  ipAddress: string;
  sequence: number;
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

type InitializeStrikerResponseBody = {
  jobUuid: string;
};

type PrepareHostRequestBody = {
  enterprise: {
    uuid?: string;
  };
  host: {
    name: string;
    password: string;
    ssh: {
      port?: number;
    };
    type: string;
    user?: string;
    uuid?: string;
  };
  redhat: {
    password?: string;
    user?: string;
  };
  target: string;
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
