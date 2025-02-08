type ProvisionServerResourceFile = {
  locations: Record<
    string,
    {
      active: boolean;
      ready: boolean;
      subnode: string;
    }
  >;
  name: string;
  nodes: string[];
  uuid: string;
};

type ProvisionServerResourceNode = {
  cpu: {
    cores: {
      total: number;
    };
  };
  description: string;
  files: string[];
  memory: {
    allocated: string;
    available: string;
    system: string;
    total: string;
  };
  name: string;
  servers: string[];
  storageGroups: string[];
  subnodes: string[];
  uuid: string;
};

type ProvisionServerResourceServer = {
  cpu: {
    cores: number;
  };
  jobs: Record<
    string,
    {
      peer: boolean;
      progress: number;
      uuid: string;
    }
  >;
  memory: {
    total: string;
  };
  name: string;
  node: string;
  uuid: string;
};

type ProvisionServerResourceStorageGroup = {
  name: string;
  node: string;
  usage: {
    free: string;
    total: string;
    used: string;
  };
  uuid: string;
};

type ProvisionServerResourceSubnode = {
  cpu: {
    cores: {
      total: number;
    };
  };
  memory: {
    total: string;
  };
  name: string;
  node: string;
  short: string;
  uuid: string;
};

type ProvisionServerResources = {
  files: Record<string, ProvisionServerResourceFile>;
  nodes: Record<string, ProvisionServerResourceNode>;
  servers: Record<string, ProvisionServerResourceServer>;
  storageGroups: Record<string, ProvisionServerResourceStorageGroup>;
  subnodes: Record<string, ProvisionServerResourceSubnode>;
};

type ServerOses = Record<string, string>;

type ServerOverviewHost = {
  name: string;
  short: string;
  type: string;
  uuid: string;
};

type ServerOverviewJob = {
  host: ServerOverviewHost;
  peer?: boolean;
  progress: number;
  uuid: string;
};

type ServerOverview = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
  host?: ServerOverviewHost;
  jobs?: Record<string, ServerOverviewJob>;
  name: string;
  state: string;
  uuid: string;
};

type ServerOverviewList = Record<string, ServerOverview>;

type ServerDetailParamsDictionary = {
  serverUUID: string;
};

type ServerDetailParsedQs = {
  resize: string;
  ss: boolean | number | string;
  vnc: boolean | number | string;
};

type ServerDetailCpu = {
  topology: {
    clusters: number;
    cores: number;
    dies: number;
    sockets: number;
    threads: number;
  };
};

type ServerDetailDisk = {
  alias: {
    name: string;
  };
  boot: {
    order: number;
  };
  device: string;
  source: {
    dev: {
      lv: Partial<{
        name: string;
        size: string;
        uuid: string;
      }>;
      path?: string;
      sg?: string;
    };
    file: Partial<{
      path: string;
      uuid: string;
    }>;
    index: number;
  };
  target: {
    bus: string;
    dev: string;
  };
  type: string;
};

type ServerDetailHostBridge = {
  id: string;
  mac: string;
  name: string;
  uuid: string;
};

type ServerDetailHostBridgeList = Record<string, ServerDetailHostBridge>;

type ServerDetailInterface = {
  alias: {
    name: string;
  };
  link: {
    state: string;
  };
  mac: {
    address: string;
  };
  model: {
    type: string;
  };
  source: {
    bridge: string;
  };
  target: {
    dev: string;
  };
  type: string;
  uuid: string;
};

type ServerDetailMemory = {
  size: string;
};

type ServerDetailVariable = {
  name: string;
  short: string;
  uuid: string;
  value: string;
};

type ServerDetail = ServerOverview & {
  bridges: ServerDetailHostBridgeList;
  definition: {
    uuid: string;
  };
  devices: {
    diskOrderBy: {
      boot: number[];
      source: number[];
    };
    disks: ServerDetailDisk[];
    interfaces: ServerDetailInterface[];
  };
  cpu: ServerDetailCpu;
  libvirt: {
    nicModels: string[];
  };
  memory: ServerDetailMemory;
  start: {
    active: boolean;
    after: string;
    delay: number;
  };
  variables: Record<string, ServerDetailVariable>;
};

type ServerDetailScreenshot = {
  screenshot: string;
  timestamp: number;
};

type ServerDetailVncInfo = {
  domain: string;
  port: number;
  protocol: string;
};

type ServerNetworkInterface = {
  device: string;
  mac: string;
  state: string;
  uuid: string;
};

type ServerNetworkInterfaceList = Record<string, ServerNetworkInterface>;

type ServerAddDiskRequestBody = {
  anvil?: string;
  size: string;
  storage: string;
};

type ServerAddIfaceRequestBody = {
  bridge: string;
  mac?: string;
  model?: string;
};

type ServerChangeIsoRequestBody = {
  anvil?: string;
  device: string;
  iso?: string;
};

type ServerDeleteIfaceRequestBody = {
  mac: string;
};

type ServerGrowDiskRequestBody = {
  anvil?: string;
  device: string;
  size: string;
};

type ServerRenameRequestBody = {
  name: string;
};

/**
 * @param target DRBD resource, which should be short host name
 */
type ServerMigrateRequestBody = {
  target: string;
};

type ServerSetBootOrderRequestBody = {
  order: string[];
};

type ServerSetCpuRequestBody = {
  cores: number;
  sockets: number;
};

type ServerSetIfaceStateRequestBody = {
  active: boolean;
  mac: string;
};

type ServerSetMemoryRequestBody = {
  size: string;
};

type ServerSetStartDependencyRequestBody = {
  active?: boolean;
  after?: string;
  delay?: number;
};

type ServerUpdateParamsDictionary = {
  uuid: string;
};

type ServerUpdateResponseBody = {
  jobUuid: string;
};
