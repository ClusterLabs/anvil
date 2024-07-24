type ManifestOverview = {
  manifestName: string;
  manifestUUID: string;
};

type ManifestDetailNetwork = {
  networkGateway: string;
  networkMinIp: string;
  networkNumber: number;
  networkSubnetMask: string;
  networkType: string;
};

type ManifestDetailNetworkList = {
  [networkId: string]: ManifestDetailNetwork;
};

type ManifestDetailFence = {
  fenceName: string;
  fencePort: string;
  fenceUuid: string;
};

type ManifestDetailFenceList = {
  [fenceId: string]: ManifestDetailFence;
};

type ManifestDetailHostNetwork = {
  networkIp: string;
  networkNumber: number;
  networkType: string;
};

type ManifestDetailHostNetworkList = {
  [networkId: string]: ManifestDetailHostNetwork;
};

type ManifestDetailUps = {
  isUsed: boolean;
  upsName: string;
  upsUuid: string;
};

type ManifestDetailUpsList = {
  [upsId: string]: ManifestDetailUps;
};

type ManifestDetailHostList = {
  [hostId: string]: {
    fences: ManifestDetailFenceList;
    hostName: string;
    hostNumber: number;
    hostType: string;
    ipmiIp: string;
    networks: ManifestDetailHostNetworkList;
    upses: ManifestDetailUpsList;
  };
};

type ManifestDetail = {
  domain: string;
  hostConfig: {
    hosts: ManifestDetailHostList;
  };
  name: string;
  networkConfig: {
    dnsCsv: string;
    mtu: number;
    networks: ManifestDetailNetworkList;
    ntpCsv: string;
  };
  prefix: string;
  sequence: number;
};

type ManifestExecutionHost = {
  id?: string;
  number: number;
  type: string;
  uuid: string;
};

type ManifestExecutionHostList = Record<string, ManifestExecutionHost>;

type ManifestTemplate = {
  domain: string;
  fences: {
    [fenceUUID: string]: {
      fenceName: string;
      fenceUUID: string;
    };
  };
  prefix: string;
  sequence: number;
  upses: {
    [upsUUID: string]: {
      upsName: string;
      upsUUID: string;
    };
  };
};

type BuildManifestRequestBody = Omit<ManifestDetail, 'name'>;

type RunManifestRequestBody = {
  debug?: number;
  description: string;
  hosts: ManifestExecutionHostList;
  password: string;
  reuseHosts?: boolean;
};
