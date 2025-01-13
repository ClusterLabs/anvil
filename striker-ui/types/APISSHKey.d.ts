type APISSHKeyConflictOverview = {
  target: {
    ip: string;
    name: string;
    short: string;
  };
};

type APISSHKeyConflictOverviewList = Record<string, APISSHKeyConflictOverview>;
