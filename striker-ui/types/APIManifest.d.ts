type APIManifestOverview = {
  manifestName: string;
  manifestUUID: string;
};

type APIManifestOverviewList = {
  [manifestUUID: string]: APIManifestOverview;
};

type APIManifestTemplateFence = {
  fenceName: string;
  fenceUUID: string;
};

type APIManifestTemplateUps = {
  upsName: string;
  upsUUID: string;
};

type APIManifestTemplateFenceList = {
  [fenceUuid: string]: APIManifestTemplateFence;
};

type APIManifestTemplateUpsList = {
  [upsUuid: string]: APIManifestTemplateUps;
};

type APIManifestTemplate = {
  domain: string;
  fences: APIManifestTemplateFenceList;
  prefix: string;
  sequence: number;
  upses: APIManifestTemplateUpsList;
};
