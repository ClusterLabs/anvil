type APISSHKeyConflictOverview = {
  [stateUUID: string]: {
    badFile: string;
    badLine: number;
    hostName: string;
    hostUUID: string;
    ipAddress: string;
    stateUUID: string;
  };
};

type APISSHKeyConflictOverviewList = {
  [hostUUID: 'local' | string]: APISSHKeyConflictOverview;
};
