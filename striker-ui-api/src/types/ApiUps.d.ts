type UpsOverview = {
  upsAgent: string;
  upsIPAddress: string;
  upsName: string;
  upsUUID: string;
};

type UpsTemplate = {
  [upsName: string]: AnvilDataUPSHash[string] & {
    links: {
      [linkId: string]: {
        linkHref: string;
        linkLabel: string;
      };
    };
  };
};
