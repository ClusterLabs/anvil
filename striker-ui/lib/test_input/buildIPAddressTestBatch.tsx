/* eslint-disable default-param-last */

import { REP_IPV4 } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

/**
 * @deprecated
 */
const buildIPAddressTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onIPv4TestFailure,
) => ({
  defaults: { ...defaults, onSuccess },
  isRequired,
  onFinishBatch,
  tests: [
    {
      test: testNotBlank,
    },
    {
      onFailure: (...args) => {
        onIPv4TestFailure(
          <>{inputName} should be a valid IPv4 address.</>,
          ...args,
        );
      },
      test: ({ value }) => REP_IPV4.test(value as string),
    },
  ],
});

export default buildIPAddressTestBatch;
