type UPSOverview = {
  upsAgent: string;
  upsIPAddress: string;
  upsName: string;
  upsUUID: string;
};

type UPSTemplate = {
  [upsName: string]: AnvilDataUPSHash[string] & {
    links: {
      [linkId: string]: {
        linkHref: string;
        linkLabel: string;
      };
    };
  };
};
