import {
  InputTest,
  TestInputFunction,
  TestInputFunctionOptions,
} from '../../types/TestInputFunction';

const testInput: TestInputFunction = ({
  inputs,
  isContinueOnFailure,
  isIgnoreOnCallbacks,
  tests = {},
} = {}): boolean => {
  const testsToRun =
    inputs ??
    Object.keys(tests).reduce<
      Exclude<TestInputFunctionOptions['inputs'], undefined>
    >((reduceContainer, id: string) => {
      reduceContainer[id] = {};
      return reduceContainer;
    }, {});

  let allResult = true;

  let setBatchCallback: (
    batch?: Partial<
      Exclude<TestInputFunctionOptions['tests'], undefined>[string]
    >,
  ) => {
    cbFinishBatch: Exclude<
      TestInputFunctionOptions['tests'],
      undefined
    >[string]['onFinishBatch'];
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

  Object.keys(testsToRun).every((id: string) => {
    const {
      defaults: { max: dMax, min: dMin, onSuccess: dOnSuccess, value: dValue },
      onFinishBatch,
      optionalTests,
      tests: requiredTests,
    } = tests[id];
    const { max = dMax, min = dMin, value = dValue } = testsToRun[id];

    const { cbFinishBatch } = setBatchCallback({ onFinishBatch });

    const runTest: (test: InputTest) => boolean = ({
      onFailure,
      onSuccess = dOnSuccess,
      test,
    }) => {
      const args = { max, min, value };
      const singleResult: boolean = test(args);

      const { cbFailure, cbSuccess } = setSingleCallback({
        onFailure,
        onSuccess,
      });

      if (singleResult) {
        cbSuccess?.call(null);
      } else {
        allResult = singleResult;

        cbFailure?.call(null, args);
      }

      return singleResult;
    };

    // Don't need to pass optional tests for input to be valid.
    optionalTests?.forEach(runTest);

    const requiredTestsResult = requiredTests.every(runTest);

    cbFinishBatch?.call(null);

    return requiredTestsResult || isContinueOnFailure;
  });

  return allResult;
};

export default testInput;
