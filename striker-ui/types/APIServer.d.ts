type APIServerState =
  | 'crashed'
  | 'idle'
  | 'in shutdown'
  | 'migrating'
  | 'paused'
  | 'pmsuspended'
  | 'running'
  | 'shut off';

type APIServerOverviewHost = {
  name: string;
  short: string;
  type: string;
  uuid: string;
};

type APIServerOverview = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
  host: APIServerOverviewHost;
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
    dev?: string;
    file?: string;
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

type APIServerDetail = Omit<APIServerOverview, 'host'> & {
  cpu: APIServerDetailCpu;
  devices: {
    diskOrderBy: {
      boot: [null, ...number[]];
      source: [null, ...number[]];
    };
    disks: APIServerDetailDisk[];
    interfaces: APIServerDetailInterface[];
  };
  host: APIServerOverviewHost & {
    bridges: Record<string, APIServerDetailHostBridge>;
  };
  libvirt: {
    nicModels: string[];
  };
  memory: APIServerDetailMemory;
  start: {
    after: null | string;
    delay: number;
  };
};

type APIServerRenameRequestBody = {
  newName: string;
};

type APIServerUpdateResponseBody = {
  jobUuid: string;
};
