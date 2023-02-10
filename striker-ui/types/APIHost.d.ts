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
  installTarget: APIHostInstallTarget;
};

type APIDeleteHostConnectionRequestBody = { [key: 'local' | string]: string[] };
