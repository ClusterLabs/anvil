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

type HostNetwork = Tree<number | string> & {
  ip: string;
  sequence: number;
  subnetMask: string;
  type: string;
};

type HostServer = {
  name: string;
  uuid: string;
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
  modified: number;
  shortHostName: string;
};

type HostOverviewList = Record<string, HostOverview>;

type HostDetail = {
  anvil?: {
    description: string;
    name: string;
    uuid: string;
  };
  configured: boolean;
  modified: number;
  name: string;
  short: string;
  status: {
    drbd: {
      maxEstimatedTimeToSync: number;
      status: string;
    };
    system: string;
  };
  type: string;
  uuid: string;
} & {
  drbdResources: Record<string, AnvilHostDrbdResource>;
  ipmi: HostIpmi;
  netconf: {
    dns: string;
    gateway: string;
    gatewayInterface: string;
    networks: Record<string, HostNetwork>;
    ntp: string;
  };
  servers: {
    all: Record<string, HostServer>;
    configured: string[];
    replicating: string[];
    running: string[];
  };
  storage: {
    volumeGroups: Record<string, AnvilDetailVolumeGroup>;
    volumeGroupTotals: {
      free: string;
      size: string;
      used: string;
    };
  };
  variables: Tree<boolean | number | string>;
};

type HostDetailList = Record<string, HostDetail>;

type InitializeStrikerNetworkForm = {
  createBridge?: string;
  interfaces: (
    | {
        mac?: string;
      }
    | null
    | undefined
  )[];
  ipAddress: string;
  sequence: number;
  subnetMask: string;
  type: string;
};

type InitializeStrikerForm = {
  adminPassword: string;
  dns?: string;
  domainName: string;
  gateway: string;
  gatewayInterface: string;
  hostName: string;
  hostNumber: number;
  networks: InitializeStrikerNetworkForm[];
  ntp?: string;
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
  dns?: string;
  gateway: string;
  gatewayInterface: string;
  hostName: string;
  networks: InitializeStrikerNetworkForm[];
  ntp?: string;
};

type SetHostInstallTargetRequestBody = {
  isEnableInstallTarget: boolean;
};

type UpdateHostParams = {
  hostUUID: string;
};
