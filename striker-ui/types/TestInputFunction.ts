export type InputTestArgs = {
  displayMax?: string;
  displayMin?: string;
  max?: bigint | number;
  min?: bigint | number;
  value?: bigint | number | null | string;
};

export type MinimalInputTestArgs = Required<
  Omit<InputTestArgs, 'displayMax' | 'displayMin'>
>;

export type InputTest = {
  onFailure?: (args: InputTestArgs) => void;
  onSuccess?: () => void;
  test: (args: MinimalInputTestArgs) => boolean;
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
