import { REP_IPV4 } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

const buildIPAddressTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { onFinishBatch, ...defaults } = {},
  onIPv4TestFailure,
) => ({
  defaults: { ...defaults, onSuccess },
  onFinishBatch,
  tests: [
    {
      onFailure: (...args) => {
        onIPv4TestFailure(
          `${inputName} should be a valid IPv4 address.`,
          ...args,
        );
      },
      test: ({ value }) => REP_IPV4.test(value as string),
    },
    { test: testNotBlank },
  ],
});

export default buildIPAddressTestBatch;
