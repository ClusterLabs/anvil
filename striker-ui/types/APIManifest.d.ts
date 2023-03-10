type APIManifestOverview = {
  manifestName: string;
  manifestUUID: string;
};

type APIManifestOverviewList = {
  [manifestUUID: string]: APIManifestOverview;
};
