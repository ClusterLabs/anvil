type FileOverview = {
  anvils: Record<
    string,
    {
      active: boolean;
      ready: boolean;
    }
  >;
  checksum: string;
  name: string;
  size: string;
  type: string;
  uuid: string;
};

type FileOverviewList = Record<string, FileOverview>;

type FileDetail = Omit<FileOverview, 'anvils'> & {
  anvils: {
    [uuid: string]: {
      description: string;
      locationUuids: string[];
      name: string;
      uuid: string;
    };
  };
  hosts: {
    [uuid: string]: {
      locationUuids: string[];
      name: string;
      type: string;
      uuid: string;
    };
  };
  locations: {
    [uuid: string]: {
      active: boolean;
      anvilUuid: string;
      hostUuid: string;
      ready: boolean;
      uuid: string;
    };
  };
};

type FileOverviewListReqQuery = {
  anvilUuid: string;
};
