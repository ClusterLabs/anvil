/* eslint-disable default-param-last */

import { REP_UUID } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';

/**
 * @deprecated
 */
const buildUUIDTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onUUIDTestFailure,
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
        onUUIDTestFailure(<>{inputName} must be a valid UUID.</>, ...args);
      },
      test: ({ value }) => REP_UUID.test(value as string),
    },
  ],
});

export default buildUUIDTestBatch;
