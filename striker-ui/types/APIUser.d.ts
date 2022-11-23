type UserOverviewMetadata = {
  userName: string;
  userUUID: string;
};

type UserOverviewMetadataList = {
  [userUUID: string]: UserOverviewMetadata;
};
