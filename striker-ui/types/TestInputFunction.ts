export type InputTestValue = bigint | number | null | string | undefined;

export type InputTestArgs = {
  compare?: InputTestValue;
  displayMax?: string;
  displayMin?: string;
  getCompare?: () => InputTestValue;
  getValue?: () => InputTestValue;
  max?: bigint | number;
  min?: bigint | number;
  value?: InputTestValue;
};

export type MinimalInputTestArgs = Required<
  Omit<InputTestArgs, 'displayMax' | 'displayMin' | 'getCompare' | 'getValue'>
>;

export type InputTest = {
  onFailure?: (args: InputTestArgs) => void;
  onSuccess?: () => void;
  test: (args: MinimalInputTestArgs) => boolean;
};

export type InputTestInputs = {
  [id: string]: Partial<InputTestArgs>;
};

export type InputTestBatches = {
  [id: string]: {
    defaults?: InputTestArgs & {
      onSuccess?: () => void;
    };
    onFinishBatch?: () => void;
    optionalTests?: Array<InputTest>;
    tests: Array<InputTest>;
  };
};

export type TestInputFunctionOptions = {
  excludeTestIds?: string[];
  inputs?: InputTestInputs;
  isContinueOnFailure?: boolean;
  isIgnoreOnCallbacks?: boolean;
  tests?: InputTestBatches;
};

export type TestInputFunction = (options?: TestInputFunctionOptions) => boolean;
