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

type APIHostStatus = 'offline' | 'booted' | 'crmd' | 'in_ccm' | 'online';

type APIHostIPMI = {
  command: string;
  ip: string;
  password: string;
  username: string;
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
  shortHostName: string;
};

type APIHostOverviewList = {
  [hostUUID: string]: APIHostOverview;
};

type APIHostNetwork = {
  createBridge?: NumberBoolean;
  ip: string;
  link1MacToSet: string;
  link1Uuid: string;
  link2MacToSet?: string;
  link2Uuid?: string;
  sequence: string;
  subnetMask: string;
  type: NetworkType;
};

type APIHostNetworkList = {
  [networkId: string]: APIHostNetwork;
};

type APIHostDetail = APIHostOverview & {
  dns?: string;
  domain?: string;
  gateway?: string;
  gatewayInterface?: string;
  installTarget?: APIHostInstallTarget;
  ipmi?: APIHostIPMI;
  networks?: APIHostNetworkList;
  organization?: string;
  prefix?: string;
  sequence?: string;
  strikerPassword?: string;
  strikerUser?: string;
};

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
