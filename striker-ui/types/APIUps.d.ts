type APIUpsTemplate = {
  [upsTypeId: string]: {
    agent: string;
    brand: string;
    description: string;
  };
};

type APIUpsOverview = {
  [upsUUID: string]: {
    upsAgent: string;
    upsIPAddress: string;
    upsName: string;
    upsUUID: string;
  };
};
