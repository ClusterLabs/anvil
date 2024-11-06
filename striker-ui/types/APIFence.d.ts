type FenceParameterType =
  | 'boolean'
  | 'integer'
  | 'second'
  | 'select'
  | 'string';

type FenceParameters = {
  [parameterId: string]: string;
};

type APIFenceOverview = {
  [fenceUUID: string]: {
    fenceAgent: string;
    fenceParameters: FenceParameters;
    fenceName: string;
    fenceUUID: string;
  };
};

type APIFenceTemplate = {
  [fenceId: string]: {
    actions: string[];
    description: string;
    parameters: {
      [parameterId: string]: {
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
    };
    switch: {
      [switchId: string]: { name: string };
    };
  };
};
