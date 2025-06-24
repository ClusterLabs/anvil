type APIUpsTemplate = {
  [upsTypeId: string]: {
    agent: string;
    brand: string;
    description: string;
    links: {
      [linkId: string]: {
        linkHref: string;
        linkLabel: string;
      };
    };
  };
};

type APIUpsOverview = {
  upsAgent: string;
  upsIPAddress: string;
  upsName: string;
  upsUUID: string;
};

type APIUpsOverviewList = Record<string, APIUpsOverview>;
