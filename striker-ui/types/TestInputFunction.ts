export type InputTestArgs = {
  max: bigint | number;
  min: bigint | number;
  value: bigint | number | string;
};

export type InputTest = {
  onFailure?: (args: InputTestArgs) => void;
  onSuccess?: () => void;
  test: (args: InputTestArgs) => boolean;
};

export type InputTestBatches = {
  [id: string]: {
    defaults: InputTestArgs & {
      onSuccess: () => void;
    };
    onFinishBatch?: () => void;
    optionalTests?: Array<InputTest>;
    tests: Array<InputTest>;
  };
};

export type TestInputFunctionOptions = {
  inputs?: {
    [id: string]: Partial<InputTestArgs>;
  };
  isContinueOnFailure?: boolean;
  isIgnoreOnCallbacks?: boolean;
  tests?: InputTestBatches;
};

export type TestInputFunction = (options?: TestInputFunctionOptions) => boolean;
