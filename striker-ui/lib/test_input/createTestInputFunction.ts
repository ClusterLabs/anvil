import testInput from './testInput';
import {
  InputTestBatches,
  TestInputFunction,
} from '../../types/TestInputFunction';

const createTestInputFunction =
  (tests: InputTestBatches) =>
  (
    ...[options, ...restArgs]: Parameters<TestInputFunction>
  ): ReturnType<TestInputFunction> =>
    testInput({ tests, ...options }, ...restArgs);

export default createTestInputFunction;
