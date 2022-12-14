type AnvilOverview = {
  anvilName: string;
  anvilUUID: string;
  hosts: Array<{
    hostName: string;
    hostUUID: string;
  }>;
};
