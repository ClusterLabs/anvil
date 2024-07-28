type APIManifestOverview = {
  manifestName: string;
  manifestUUID: string;
};

type APIManifestOverviewList = {
  [manifestUUID: string]: APIManifestOverview;
};

type APIManifestDetail = ManifestAnId & {
  anvil?: {
    description: string;
    hosts: Record<string, { uuid: string }>;
    uuid: string;
  };
  hostConfig: ManifestHostConfig;
  name: string;
  networkConfig: ManifestNetworkConfig;
  uuid?: string;
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

type APIBuildManifestRequestBody = Omit<APIManifestDetail, 'name' | 'uuid'>;
