import { REP_UUID } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

const buildUUIDTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { onFinishBatch, ...defaults } = {},
  onUUIDTestFailure,
) => ({
  defaults: { ...defaults, onSuccess },
  onFinishBatch,
  tests: [
    {
      onFailure: (...args) => {
        onUUIDTestFailure(`${inputName} must be a valid UUID.`, ...args);
      },
      test: ({ value }) => REP_UUID.test(value as string),
    },
    { test: testNotBlank },
  ],
});

export default buildUUIDTestBatch;
