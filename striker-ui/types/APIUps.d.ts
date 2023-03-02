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
  [upsUUID: string]: {
    upsAgent: string;
    upsIPAddress: string;
    upsName: string;
    upsUUID: string;
  };
};
