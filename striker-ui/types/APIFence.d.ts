type APIFenceTemplate = {
  [fenceId: string]: {
    actions: string[];
    description: string;
    parameters: {
      [parameterId: string]: {
        content_type: 'boolean' | 'integer' | 'second' | 'select' | 'string';
        default: string;
        deprecated: number;
        description: string;
        obsoletes: number;
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
