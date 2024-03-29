type InputTestValue = bigint | boolean | number | null | string | undefined;

type InputTestArgs = {
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

type MinimalInputTestArgs = Required<
  Omit<
    InputTestArgs,
    | 'displayMax'
    | 'displayMin'
    | 'getCompare'
    | 'getValue'
    | 'isIgnoreOnCallbacks'
  >
>;

type CallbackAppendArgs = {
  append: {
    [arg: string]: InputTestValue;
  };
};

type InputTestFailureCallback = (
  args: InputTestArgs & CallbackAppendArgs,
) => void;

type InputTestFailureAppendCallback = (
  message: import('react').ReactNode,
  ...args: Parameters<InputTestFailureCallback>
) => void;

type InputTestSuccessCallback = (args: CallbackAppendArgs) => void;

type InputTest = {
  onFailure?: InputTestFailureCallback;
  onSuccess?: InputTestSuccessCallback;
  test: (args: MinimalInputTestArgs & CallbackAppendArgs) => boolean;
};

type InputTestInputs = {
  [id: string]: Partial<InputTestArgs>;
};

type InputTestBatchFinishCallback = (result: boolean, id: string) => void;

type InputTestBatch = {
  defaults?: InputTestArgs & {
    onSuccess?: InputTestSuccessCallback;
  };
  isRequired?: boolean;
  onFinishBatch?: InputTestBatchFinishCallback;
  optionalTests?: Array<InputTest>;
  tests: Array<InputTest>;
};

type BuildInputTestBatchFunction = (
  inputName: string,
  onSuccess: InputTestSuccessCallback,
  options?: InputTestBatch['defaults'] &
    Pick<InputTestBatch, 'isRequired' | 'onFinishBatch'>,
  ...onFailureAppends: InputTestFailureAppendCallback[]
) => InputTestBatch;

type InputTestBatches = {
  [id: string]: InputTestBatch;
};

type TestInputFunctionOptions = {
  excludeTestIds?: string[];
  excludeTestIdsRe?: RegExp;
  inputs?: InputTestInputs;
  isContinueOnFailure?: boolean;
  isIgnoreOnCallbacks?: boolean;
  isTestAll?: boolean;
  tests?: InputTestBatches;
};

type TestInputFunction = (options?: TestInputFunctionOptions) => boolean;
