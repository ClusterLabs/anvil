import testInput from './testInput';

/**
 * @deprecated
 */
const createTestInputFunction =
  (
    tests: InputTestBatches,
    {
      excludeTestIds: defaultExcludeTestIds = [],
      ...restDefaultOptions
    }: Omit<TestInputFunctionOptions, 'inputs' | 'tests'> = {},
  ) =>
  ({
    excludeTestIds = [],
    ...restOptions
  }: Parameters<TestInputFunction>[0] = {}): ReturnType<TestInputFunction> =>
    testInput({
      tests,
      excludeTestIds: [...defaultExcludeTestIds, ...excludeTestIds],
      ...restDefaultOptions,
      ...restOptions,
    });

export default createTestInputFunction;
