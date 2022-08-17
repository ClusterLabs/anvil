export type InputTestValue = bigint | number | null | string | undefined;

export type InputTestArgs = {
  compare?: InputTestValue[];
  displayMax?: string;
  displayMin?: string;
  getCompare?: () => InputTestValue[];
  getValue?: () => InputTestValue;
  max?: bigint | number;
  min?: bigint | number;
  value?: InputTestValue;
};

export type MinimalInputTestArgs = Required<
  Omit<InputTestArgs, 'displayMax' | 'displayMin' | 'getCompare' | 'getValue'>
>;

export type CallbackAppendArgs = {
  append: {
    [arg: string]: InputTestValue;
  };
};

export type InputTestSuccessCallback = () => void;

export type InputTest = {
  onFailure?: (args: InputTestArgs & CallbackAppendArgs) => void;
  onSuccess?: InputTestSuccessCallback;
  test: (args: MinimalInputTestArgs & CallbackAppendArgs) => boolean;
};

export type InputTestInputs = {
  [id: string]: Partial<InputTestArgs>;
};

export type InputTestBatches = {
  [id: string]: {
    defaults?: InputTestArgs & {
      onSuccess?: InputTestSuccessCallback;
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
  isTestAll?: boolean;
  tests?: InputTestBatches;
};

export type TestInputFunction = (options?: TestInputFunctionOptions) => boolean;
