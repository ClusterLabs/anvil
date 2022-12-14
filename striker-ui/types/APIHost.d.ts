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

type APIHostDetail = {
  hostName: string;
  hostUUID: string;
  installTarget: APIHostInstallTarget;
  shortHostName: string;
};

type APIDeleteHostConnectionRequestBody = { [key: 'local' | string]: string[] };
