type ServerState =
  | 'crashed'
  | 'deleting'
  | 'idle'
  | 'in bootup'
  | 'in shutdown'
  | 'migrating'
  | 'paused'
  | 'pmsuspended'
  | 'provisioning'
  | 'renaming'
  | 'running'
  | 'shut off';

type ServerMinimum = {
  ip: {
    address: string;
    timestamp: number;
  };
  name: string;
  state: ServerState;
  uuid: string;
};

type APIServerOses = Record<string, string>;

type APIProvisionServerResourceFile = {
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

type APIProvisionServerResourceNode = {
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

type ProvisionServerResourceNode = Omit<
  APIProvisionServerResourceNode,
  'memory'
> & {
  memory: {
    allocated: bigint;
    available: bigint;
    system: bigint;
    total: bigint;
  };
};

type APIProvisionServerResourceServer = {
  cpu: {
    cores: number;
  };
  jobs: Record<
    string,
    {
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

type ProvisionServerResourceServer = Omit<
  APIProvisionServerResourceServer,
  'memory'
> & {
  memory: {
    total: bigint;
  };
};

type APIProvisionServerResourceStorageGroup = {
  name: string;
  node: string;
  usage: {
    free: string;
    total: string;
    used: string;
  };
  uuid: string;
};

type ProvisionServerResourceStorageGroup = Omit<
  APIProvisionServerResourceStorageGroup,
  'usage'
> & {
  usage: {
    free: bigint;
    total: bigint;
    used: bigint;
  };
};

type APIProvisionServerResourceSubnode = {
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

type ProvisionServerResourceSubnode = Omit<
  APIProvisionServerResourceSubnode,
  'memory'
> & {
  memory: {
    total: bigint;
  };
};

type APIProvisionServerResources = {
  files: Record<string, APIProvisionServerResourceFile>;
  nodes: Record<string, APIProvisionServerResourceNode>;
  servers: Record<string, APIProvisionServerResourceServer>;
  storageGroups: Record<string, APIProvisionServerResourceStorageGroup>;
  subnodes: Record<string, APIProvisionServerResourceSubnode>;
};

type ProvisionServerResources = {
  files: Record<string, APIProvisionServerResourceFile>;
  nodes: Record<string, ProvisionServerResourceNode>;
  servers: Record<string, ProvisionServerResourceServer>;
  storageGroups: Record<string, ProvisionServerResourceStorageGroup>;
  subnodes: Record<string, ProvisionServerResourceSubnode>;
};

type APIProvisionServerRequestBody = {
  serverName: string;
  cpuCores: number;
  memory: string;
  virtualDisks: {
    storageSize: string;
    storageGroupUUID: string;
  }[];
  installISOFileUUID: string;
  driverISOFileUUID: string;
  anvilUUID: string;
  optimizeForOS: string;
};

type APIServerOverviewAnvil = {
  description: string;
  name: string;
  uuid: string;
};

type APIServerOverviewHost = {
  name: string;
  short: string;
  type: string;
  uuid: string;
};

type APIServerOverviewJob = {
  host: APIServerOverviewHost;
  peer?: boolean;
  progress: number;
  uuid: string;
};

type APIServerOverview = ServerMinimum & {
  anvil: APIServerOverviewAnvil;
  host?: APIServerOverviewHost;
  jobs?: Record<string, APIServerOverviewJob>;
};

type APIServerOverviewList = Record<string, APIServerOverview>;

type APIServerDetailCpu = {
  topology: {
    clusters: number;
    cores: number;
    dies: number;
    sockets: number;
    threads: number;
  };
};

type APIServerDetailDisk = {
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
      path?: string;
      uuid?: string;
    }>;
    index: number;
  };
  target: {
    bus: string;
    dev: string;
  };
  type: string;
};

type APIServerDetailInterface = {
  alias: {
    name: string;
  };
  ip: {
    address: string;
    timestamp: number;
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

type APIServerDetailMemory = {
  size: string;
};

type APIServerDetailProtect = {
  drUuid: string;
  protocol: string;
  status: {
    connection: string;
    maxEstimatedTimeToSync: number;
    overall: string;
  };
};

type APIServerDetailHostBridge = {
  id: string;
  mac: string;
  name: string;
  uuid: string;
};

type APIServerDetail = APIServerOverview & {
  bridges: Record<string, APIServerDetailHostBridge>;
  cpu: APIServerDetailCpu;
  devices: {
    diskOrderBy: {
      boot: [null, ...number[]];
      source: [null, ...number[]];
    };
    disks: APIServerDetailDisk[];
    interfaces: APIServerDetailInterface[];
  };
  libvirt: {
    nicModels: string[];
  };
  memory: APIServerDetailMemory;
  protect: Record<string, APIServerDetailProtect>;
  start: {
    active: boolean;
    after: null | string;
    delay: number;
  };
};

/**
 * @prop timestamp - unit: seconds
 */
type APIServerDetailScreenshot = {
  screenshot: string;
  timestamp: number;
};

type APIServerRenameRequestBody = {
  newName: string;
};

type APIServerProtectRequestBody = {
  lvmVgUuid?: string;
  operation: string;
  protocol?: string;
};

type APIServerUpdateResponseBody = {
  jobUuid: string;
};
