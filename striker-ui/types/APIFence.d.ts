type FenceParameterType =
  | 'boolean'
  | 'integer'
  | 'second'
  | 'select'
  | 'string';

type FenceParameters = Record<string, string>;

type APIFenceOverview = {
  fenceAgent: string;
  fenceParameters: FenceParameters;
  fenceName: string;
  fenceUUID: string;
};

type APIFenceOverviewList = Record<string, APIFenceOverview>;

type APIFenceSpecParameter = {
  content_type: FenceParameterType;
  default?: string;
  deprecated: number;
  description: string;
  obsoletes: 0 | string;
  options?: string[];
  replacement: string;
  required: '0' | '1';
  switches: string;
  unique: '0' | '1';
};

type APIFenceSpecParameterList = Record<string, APIFenceSpecParameter>;

type APIFenceSpecSwitch = {
  name: string;
};

type APIFenceSpecSwitchList = Record<string, APIFenceSpecSwitch>;

type APIFenceSpec = {
  actions: string[];
  description: string;
  parameters: APIFenceSpecParameterList;
  switch: APIFenceSpecSwitchList;
};

type APIFenceTemplate = Record<string, APIFenceSpec>;

type APIFenceRequestBody = {
  agent: string;
  name: string;
  parameters: Record<string, string>;
};
