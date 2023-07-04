type APIHostConnectionOverviewList = {
  local: {
    inbound: {
      ipAddress: {
        [ipAddress: string]: {
          hostUUID: string;
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

type APIHostOverview = {
  hostName: string;
  hostType: string;
  hostUUID: string;
  shortHostName: string;
};

type APIHostOverviewList = {
  [hostUUID: string]: APIHostOverview;
};

type APIHostDetail = APIHostOverview & {
  dns: string;
  domain?: string;
  gateway: string;
  gatewayInterface: string;
  installTarget: APIHostInstallTarget;
  networks: {
    [networkId: string]: {
      createBridge?: NumberBoolean;
      ip: string;
      link1MacToSet: string;
      link1Uuid: string;
      link2MacToSet?: string;
      link2Uuid?: string;
      subnetMask: string;
      type: NetworkType;
    };
  };
  organization?: string;
  prefix?: string;
  sequence?: string;
  strikerPassword?: string;
  strikerUser?: string;
};

type APIDeleteHostConnectionRequestBody = { [key: 'local' | string]: string[] };
