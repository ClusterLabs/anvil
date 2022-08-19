export type InputTestValue =
  | bigint
  | boolean
  | number
  | null
  | string
  | undefined;

export type InputTestArgs = {
  compare?: InputTestValue[];
  displayMax?: string;
  displayMin?: string;
  getCompare?: () => InputTestValue[];
  getValue?: () => InputTestValue;
  isIgnoreOnCallbacks?: boolean;
  max?: bigint | number;
  min?: bigint | number;
  value?: InputTestValue;
};

export type MinimalInputTestArgs = Required<
  Omit<
    InputTestArgs,
    | 'displayMax'
    | 'displayMin'
    | 'getCompare'
    | 'getValue'
    | 'isIgnoreOnCallbacks'
  >
>;

export type CallbackAppendArgs = {
  append: {
    [arg: string]: InputTestValue;
  };
};

export type InputTestFailureCallback = (
  args: InputTestArgs & CallbackAppendArgs,
) => void;

export type InputTestSuccessCallback = (args: CallbackAppendArgs) => void;

export type InputTest = {
  onFailure?: InputTestFailureCallback;
  onSuccess?: InputTestSuccessCallback;
  test: (args: MinimalInputTestArgs & CallbackAppendArgs) => boolean;
};

export type InputTestInputs = {
  [id: string]: Partial<InputTestArgs>;
};

export type InputTestBatchFinishCallback = () => void;

export type InputTestBatches = {
  [id: string]: {
    defaults?: InputTestArgs & {
      onSuccess?: InputTestSuccessCallback;
    };
    onFinishBatch?: InputTestBatchFinishCallback;
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
