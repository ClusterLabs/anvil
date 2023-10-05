export const sanitizeSQLParam = (variable: string): string =>
  variable.replace(/'/g, `''`);
