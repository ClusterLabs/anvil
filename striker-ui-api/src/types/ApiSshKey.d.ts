type SshKeyConflict = {
  [stateUUID: string]: {
    badFile: string;
    badLine: number;
    hostName: string;
    hostUUID: string;
    ipAddress: string;
    stateUUID: string;
  };
};

type DeleteSshKeyConflictRequestBody = Record<string, string[]>;
