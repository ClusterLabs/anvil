export const sanitizeSQLParam = (variable: string): string =>
  variable.replaceAll(/[']/g, '');
