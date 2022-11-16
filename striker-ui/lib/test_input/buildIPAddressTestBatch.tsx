import { REP_IPV4 } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

const buildIPAddressTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { getValue } = {},
  onIPv4TestFailure,
) => ({
  defaults: { getValue, onSuccess },
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
