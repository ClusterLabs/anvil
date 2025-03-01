type SshKeyConflict = {
  target: {
    ip: string;
    name: string;
    short: string;
  };
};

type SshKeyConflictList = Record<string, SshKeyConflict>;

type DeleteSshKeyConflictRequestBody = {
  badKeys: string[];
  badHost: {
    uuid?: string;
  };
};

type DeleteSshKeyConflictResponseBody = {
  jobs: Record<
    string,
    {
      local: boolean;
      uuid: string;
    }
  >;
};
