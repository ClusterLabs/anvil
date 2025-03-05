type BuildJobDataOptions<Value = unknown> = {
  getValue?: (value: Value) => string;
  skip?: (value: Value) => boolean;
};

export const buildJobData = <Value = unknown>(
  entries: [string, Value][],
  {
    getValue = (v) => String(v),
    skip = (v) => [null, undefined].some((bad) => v === bad),
  }: BuildJobDataOptions<Value> = {},
) =>
  entries
    .reduce<string>((previous, [key, value]) => {
      if (skip(value)) {
        return previous;
      }

      previous += `${key}=${getValue(value)}\\n`;

      return previous;
    }, '')
    .trim();

export const buildJobDataFromObject = <Value = unknown>(
  obj: Record<string, Value>,
  options?: BuildJobDataOptions<Value>,
) => {
  const entries = Object.entries<Value>(obj);

  return buildJobData<Value>(entries, options);
};
