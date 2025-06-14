/* eslint-disable complexity */

type TestCallbacks = Pick<InputTest, 'onFailure' | 'onSuccess'>;

const cbEmptySetter = () => ({});

const cbSetter = ({
  onFailure,
  onSuccess,
}: Pick<InputTest, 'onFailure' | 'onSuccess'>) => ({
  cbFailure: onFailure,
  cbSuccess: onSuccess,
});

const evalIsIgnoreOnCallbacks = ({
  isIgnoreOnCallbacks,
  onFinishBatch,
}: {
  isIgnoreOnCallbacks?: boolean;
  onFinishBatch?: InputTestBatchFinishCallback;
}): {
  cbFinishBatch?: InputTestBatchFinishCallback;
  setTestCallbacks: (testCallbacks: TestCallbacks) => {
    cbFailure?: InputTestFailureCallback;
    cbSuccess?: InputTestSuccessCallback;
  };
} =>
  isIgnoreOnCallbacks
    ? {
        setTestCallbacks: cbEmptySetter,
      }
    : {
        cbFinishBatch: onFinishBatch,
        setTestCallbacks: cbSetter,
      };

const nullishSet = <T>(a: T | undefined, b: T) => a ?? b;
const orSet = <T>(a: T | undefined, b: T) => a || b;

/**
 * @deprecated
 */
const testInput: TestInputFunction = ({
  excludeTestIds = [],
  excludeTestIdsRe,
  inputs = {},
  isContinueOnFailure,
  isIgnoreOnCallbacks: isIgnoreAllOnCallbacks,
  isTestAll = Object.keys(inputs).length === 0,
  tests = {},
} = {}): boolean => {
  const allExcludeIds = [...excludeTestIds];

  let testsToRun: InputTestInputs = {};
  let allResult = true;

  if (isTestAll) {
    Object.keys(tests).forEach((id: string) => {
      testsToRun[id] = {};
    });
  }

  testsToRun = { ...testsToRun, ...inputs };

  if (excludeTestIdsRe) {
    Object.keys(testsToRun).forEach((id: string) => {
      if (excludeTestIdsRe.test(id)) {
        allExcludeIds.push(id);
      }
    });
  }

  allExcludeIds.forEach((id: string) => {
    delete testsToRun[id];
  });

  Object.keys(testsToRun).every((id: string) => {
    const {
      defaults: {
        compare: dCompare = [],
        displayMax: dDisplayMax,
        displayMin: dDisplayMin,
        getCompare: dGetCompare,
        getValue: dGetValue,
        isIgnoreOnCallbacks: dIsIgnoreOnCallbacks = isIgnoreAllOnCallbacks,
        max: dMax = 0,
        min: dMin = 0,
        onSuccess: dOnSuccess,
        value: dValue = null,
      } = {},
      isRequired = false,
      onFinishBatch,
      optionalTests,
      tests: requiredTests,
    } = tests[id];
    const isOptional = !isRequired;
    const {
      getCompare = dGetCompare,
      getValue = dGetValue,
      isIgnoreOnCallbacks = dIsIgnoreOnCallbacks,
      max = dMax,
      min = dMin,
      compare = nullishSet(getCompare?.call(null), dCompare),
      value = nullishSet(getValue?.call(null), dValue),
      displayMax = orSet(dDisplayMax, String(max)),
      displayMin = orSet(dDisplayMin, String(min)),
    } = testsToRun[id];

    const { cbFinishBatch, setTestCallbacks } = evalIsIgnoreOnCallbacks({
      isIgnoreOnCallbacks,
      onFinishBatch,
    });

    if (!value && isOptional) {
      cbFinishBatch?.call(null, true, id);

      return true;
    }

    const runTest: (test: InputTest) => boolean = ({
      onFailure,
      onSuccess = dOnSuccess,
      test,
    }) => {
      const append: CallbackAppendArgs['append'] = {};
      const singleResult: boolean = test({
        append,
        compare,
        max,
        min,
        value,
      });

      const { cbFailure, cbSuccess } = setTestCallbacks({
        onFailure,
        onSuccess,
      });

      if (singleResult) {
        cbSuccess?.call(null, { append });
      } else {
        allResult = singleResult;

        cbFailure?.call(null, {
          append,
          compare,
          displayMax,
          displayMin,
          max,
          min,
          value,
        });
      }

      return singleResult;
    };

    // Don't need to pass optional tests for input to be valid.
    optionalTests?.forEach(runTest);

    const requiredTestsResult = requiredTests.every(runTest);

    // Log for debug testing only.
    // (() => {
    //   console.log(
    //     `[${requiredTestsResult ? 'PASS' : 'FAILED'}]id=${id},getValue=${
    //       getValue !== undefined
    //     },value=${value}`,
    //   );
    // })();

    cbFinishBatch?.call(null, requiredTestsResult, id);

    return requiredTestsResult || isContinueOnFailure;
  });

  return allResult;
};

export default testInput;
