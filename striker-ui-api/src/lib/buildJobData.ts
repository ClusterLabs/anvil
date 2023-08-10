export const buildJobData = <T extends [string, unknown][]>({
  entries,
  getValue = (v) => String(v),
}: {
  entries: T;
  getValue?: (value: T[number][1]) => string;
}) =>
  entries
    .reduce<string>((previous, [key, value]) => {
      previous += `${key}=${getValue(value)}\\n`;

      return previous;
    }, '')
    .trim();

export const buildJobDataFromObject = <T extends Record<string, unknown>>({
  obj,
  ...rest
}: Omit<Parameters<typeof buildJobData>[0], 'entries'> & { obj: T }) =>
  buildJobData({ entries: Object.entries(obj), ...rest });
