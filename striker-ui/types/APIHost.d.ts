type APIHostConnectionOverviewList = {
  local: {
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
};

type APIHostInstallTarget = 'enabled' | 'disabled';

type APIHostStatus = 'powered off' | 'booted' | 'crmd' | 'in_ccm' | 'online';

type APIHostDrbdResource = {
  connection: {
    state: string;
  };
  name: string;
  replication: {
    estimatedTimeToSync: number;
    state: string;
  };
  uuid: string;
};

type APIHostIPMI = {
  command: string;
  ip: string;
  password: string;
  username: string;
};
type APIHostNetwork = Tree<boolean | number | string> & {
  createBridge?: boolean;
  ip: string;
  link1MacToSet: string;
  link1Uuid: string;
  link2MacToSet?: string;
  link2Uuid?: string;
  sequence: number;
  subnetMask: string;
  type: string;
};

type APIHostNetworkList = Record<string, APIHostNetwork>;

type APIHostServer = {
  name: string;
  uuid: string;
};

type APIHostOverview = {
  anvil?: {
    name: string;
    uuid: string;
  };
  hostConfigured: boolean;
  hostName: string;
  hostStatus: APIHostStatus;
  hostType: string;
  hostUUID: string;
  modified: number;
  shortHostName: string;
};

type APIHostOverviewList = Record<string, APIHostOverview>;

// TODO: replace type host overview with the first block of host detail after
// making the same changes to the endpoint
type APIHostDetail = {
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
  drbdResources: Record<string, APIHostDrbdResource>;
  ipmi: APIHostIPMI;
  netconf: {
    dns: string;
    gateway: string;
    gatewayInterface: string;
    networks: Record<string, APIHostNetwork>;
    ntp: string;
  };
  servers: {
    // 1 server can only be protected by 1 DR host
    all: Record<string, APIHostServer>;
    configured: string[];
    replicating: string[];
    running: string[];
  };
  storage: {
    volumeGroups: Record<string, APIAnvilVolumeGroup>;
    volumeGroupTotals: {
      free: string;
      size: string;
      used: string;
    };
  };
  variables: Tree<boolean | number | string> & {
    domain?: string;
    installTarget?: APIHostInstallTarget;
    organization?: string;
    prefix?: string;
    sequence?: number;
    strikerPassword?: string;
    strikerUser?: string;
  };
};

type APIHostDetailList = Record<string, APIHostDetail>;

type APIHostDetailCalcable = Omit<APIHostDetail, 'storage'> & {
  storage: {
    volumeGroups: Record<string, APIAnvilVolumeGroupCalcable>;
    volumeGroupTotals: {
      free: bigint;
      size: bigint;
      used: bigint;
    };
  };
};

type APIHostDetailCalcableList = Record<string, APIHostDetailCalcable>;

type APIDeleteHostConnectionRequestBody = {
  [key: 'local' | string]: string[];
};

type APIStrikerInitResponseBody = {
  jobUuid: string;
};

type APIPrepareHostRequestBody = {
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
