export const buildJobData = <T extends [string, unknown][]>({
  entries,
  getValue = (v) => String(v),
  skip = (v) => [null, undefined].some((bad) => v === bad),
}: {
  entries: T;
  getValue?: (value: T[number][1]) => string;
  skip?: (value: T[number][1]) => boolean;
}) =>
  entries
    .reduce<string>((previous, [key, value]) => {
      if (skip(value)) {
        return previous;
      }

      previous += `${key}=${getValue(value)}\\n`;

      return previous;
    }, '')
    .trim();

export const buildJobDataFromObject = <T extends Record<string, unknown>>(
  obj: T,
  options?: Omit<Parameters<typeof buildJobData>[0], 'entries'>,
) => buildJobData({ entries: Object.entries(obj), ...options });
