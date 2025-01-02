type APIServerState =
  | 'crashed'
  | 'idle'
  | 'in shutdown'
  | 'migrating'
  | 'paused'
  | 'pmsuspended'
  | 'provisioning'
  | 'running'
  | 'shut off';

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

type APIServerOverview = {
  anvil: APIServerOverviewAnvil;
  host?: APIServerOverviewHost;
  jobs?: Record<string, APIServerOverviewJob>;
  name: string;
  state: APIServerState;
  uuid: string;
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

type APIServerUpdateResponseBody = {
  jobUuid: string;
};
