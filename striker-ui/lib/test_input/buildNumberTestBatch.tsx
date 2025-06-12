import testRange from './testRange';
import toNumber from '../toNumber';

/**
 * @deprecated
 */
const buildNumberTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onIntTestFailure?,
  onFloatTestFailure?,
  onRangeTestFailure?,
) => {
  const tests: InputTest[] = [];

  if (onIntTestFailure) {
    tests.push({
      onFailure: (...args) => {
        onIntTestFailure(<>{inputName} must be a valid integer.</>, ...args);
      },
      test: ({ value }) => Number.isSafeInteger(toNumber(value)),
    });
  } else if (onFloatTestFailure) {
    tests.push({
      onFailure: (...args) => {
        onFloatTestFailure(
          <>{inputName} must be a valid floating-point number.</>,
          ...args,
        );
      },
      test: ({ value }) => Number.isFinite(toNumber(value, 'parseFloat')),
    });
  }

  if (onRangeTestFailure) {
    tests.push({
      onFailure: (...args) => {
        const { displayMax, displayMin } = args[0];

        onRangeTestFailure(
          <>
            {inputName} is expected to be between {displayMin} and {displayMax}.
          </>,
          ...args,
        );
      },
      test: testRange,
    });
  }

  return {
    defaults: { ...defaults, onSuccess },
    isRequired,
    onFinishBatch,
    tests,
  };
};

export default buildNumberTestBatch;
