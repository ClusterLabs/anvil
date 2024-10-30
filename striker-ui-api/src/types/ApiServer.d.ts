type ServerOverview = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
  host: {
    name: string;
    short: string;
    type: string;
    uuid: string;
  };
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
};

type ServerDetailMemory = {
  size: string;
};

type ServerDetail = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
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
  host: {
    bridges: ServerDetailHostBridgeList;
    name: string;
    short: string;
    type: string;
    uuid: string;
  };
  memory: ServerDetailMemory;
  name: string;
  start: {
    after: string;
    delay: number;
  };
  state: string;
  uuid: string;
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

type ServerRenameRequestBody = {
  newName: string;
};

type ServerUpdateParamsDictionary = {
  uuid: string;
};

type ServerUpdateResponseBody = {
  jobUuid: string;
};
