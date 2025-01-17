type APISSHKeyConflictOverview = {
  target: {
    ip: string;
    name: string;
    short: string;
  };
};

type APISSHKeyConflictOverviewList = Record<string, APISSHKeyConflictOverview>;

type APIDeleteSSHKeyConflictRequestBody = {
  badKeys: string[];
};

type APIDeleteSSHKeyConflictResponseBody = {
  jobs: Record<
    string,
    {
      uuid: string;
    }
  >;
};
