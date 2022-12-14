const createFunction = (
  {
    conditionFn = () => true,
    str = '',
    condition = conditionFn() && str.length === 0,
  }: {
    condition?: boolean;
    conditionFn?: (...args: unknown[]) => boolean;
    str?: string;
  },
  fn: () => unknown,
  ...fnArgs: Parameters<typeof fn>
): (() => unknown) | undefined =>
  condition ? fn.bind(null, ...fnArgs) : undefined;

export default createFunction;
