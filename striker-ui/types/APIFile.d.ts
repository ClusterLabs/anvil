type APIFileOverview = {
  checksum: string;
  name: string;
  size: string;
  type: FileType;
  uuid: string;
};

type APIFileDetail = APIFileOverview & {
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

type APIFileOverviewList = {
  [uuid: string]: APIFileOverview;
};

type APIEditFileRequestBody = {
  fileName: string;
  fileType: FileType;
  fileUUID: string;
  fileLocations: Array<{
    fileLocationUUID: string;
    isFileLocationActive: boolean;
  }>;
};
