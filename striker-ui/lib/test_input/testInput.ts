import {
  InputTest,
  InputTestBatches,
  InputTestInputs,
  CallbackAppendArgs,
  TestInputFunction,
} from '../../types/TestInputFunction';

const testInput: TestInputFunction = ({
  excludeTestIds = [],
  inputs = {},
  isContinueOnFailure,
  isIgnoreOnCallbacks,
  isTestAll = Object.keys(inputs).length === 0,
  tests = {},
} = {}): boolean => {
  let testsToRun: InputTestInputs = {};
  let allResult = true;

  let setBatchCallback: (batch?: Partial<InputTestBatches[string]>) => {
    cbFinishBatch: InputTestBatches[string]['onFinishBatch'];
  } = () => ({ cbFinishBatch: undefined });
  let setSingleCallback: (test?: Partial<InputTest>) => {
    cbFailure: InputTest['onFailure'];
    cbSuccess: InputTest['onSuccess'];
  } = () => ({ cbFailure: undefined, cbSuccess: undefined });

  if (!isIgnoreOnCallbacks) {
    setBatchCallback = ({ onFinishBatch } = {}) => ({
      cbFinishBatch: onFinishBatch,
    });
    setSingleCallback = ({ onFailure, onSuccess } = {}) => ({
      cbFailure: onFailure,
      cbSuccess: onSuccess,
    });
  }

  if (isTestAll) {
    Object.keys(tests).forEach((id: string) => {
      testsToRun[id] = {};
    });
  }

  testsToRun = { ...testsToRun, ...inputs };

  excludeTestIds.forEach((id: string) => {
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
        max: dMax = 0,
        min: dMin = 0,
        onSuccess: dOnSuccess,
        value: dValue = null,
      } = {},
      onFinishBatch,
      optionalTests,
      tests: requiredTests,
    } = tests[id];
    const {
      getCompare = dGetCompare,
      getValue = dGetValue,
      max = dMax,
      min = dMin,
      compare = getCompare?.call(null) ?? dCompare,
      value = getValue?.call(null) ?? dValue,
      displayMax = dDisplayMax || String(max),
      displayMin = dDisplayMin || String(min),
    } = testsToRun[id];

    const { cbFinishBatch } = setBatchCallback({ onFinishBatch });

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

      const { cbFailure, cbSuccess } = setSingleCallback({
        onFailure,
        onSuccess,
      });

      if (singleResult) {
        cbSuccess?.call(null);
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

    cbFinishBatch?.call(null);

    return requiredTestsResult || isContinueOnFailure;
  });

  return allResult;
};

export default testInput;
