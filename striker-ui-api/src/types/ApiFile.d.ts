type FileOverview = {
  checksum: string;
  name: string;
  size: string;
  type: string;
  uuid: string;
};

type FileOverviewList = Record<string, FileOverview>;

type FileDetail = FileOverview & {
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
      uuid: string;
    };
  };
};
