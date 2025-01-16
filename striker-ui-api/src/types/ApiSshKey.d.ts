type SshKeyConflict = {
  target: {
    ip: string;
    name: string;
    short: string;
  };
};

type SshKeyConflictList = Record<string, SshKeyConflict>;

type DeleteSshKeyConflictRequestBody = Record<string, string[]>;
