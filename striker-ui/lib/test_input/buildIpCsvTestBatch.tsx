import { REP_IPV4_CSV } from '../consts/REG_EXP_PATTERNS';

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
      onFailure: (...args) => {
        onIpCsvTestFailure(
          `${inputName} must be one or more valid IPv4 addresses separated by comma; without trailing comma.`,
          ...args,
        );
      },
      test: ({ value }) => REP_IPV4_CSV.test(value as string),
    },
  ],
});

export default buildIpCsvTestBatch;
