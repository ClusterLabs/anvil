type APIFileOverview = {
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
  type: FileType;
  uuid: string;
};

type APIFileDetail = Omit<APIFileOverview, 'anvils'> & {
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
  path: {
    directory: string;
    full: string;
  };
};

type APIFileOverviewList = Record<string, APIFileOverview>;

type APIEditFileRequestBody = {
  fileName: string;
  fileType: FileType;
  fileUUID: string;
  fileLocations: Array<{
    fileLocationUUID: string;
    isFileLocationActive: boolean;
  }>;
};
