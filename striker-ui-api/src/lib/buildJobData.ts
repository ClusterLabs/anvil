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
