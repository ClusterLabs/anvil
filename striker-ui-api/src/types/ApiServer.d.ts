type ServerOverviewHost = {
  name: string;
  short: string;
  type: string;
  uuid: string;
};

type ServerOverview = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
  host: ServerOverviewHost;
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
    dev: string;
    file: string;
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

type ServerDetail = Omit<ServerOverview, 'host'> & {
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
  host: ServerOverviewHost & {
    bridges: ServerDetailHostBridgeList;
  };
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

type ServerRenameRequestBody = {
  newName: string;
};

type ServerUpdateParamsDictionary = {
  uuid: string;
};

type ServerUpdateResponseBody = {
  jobUuid: string;
};
