type HostConnectionOverview = {
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
