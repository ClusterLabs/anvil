export const cap = (
  value: string,
  { locales }: { locales?: string | string[] } = {},
) => `${value[0].toLocaleUpperCase(locales)}${value.slice(1)}`;
