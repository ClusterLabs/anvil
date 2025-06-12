/* eslint-disable default-param-last */

import { REP_IPV4_CSV } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

/**
 * @deprecated
 */
const buildIpCsvTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onIpCsvTestFailure,
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
        onIpCsvTestFailure(
          <>
            {inputName} must be one or more valid IPv4 addresses separated by
            comma(s); without trailing comma.
          </>,
          ...args,
        );
      },
      test: ({ value }) => REP_IPV4_CSV.test(value as string),
    },
  ],
});

export default buildIpCsvTestBatch;
