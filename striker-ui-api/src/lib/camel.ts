import { cap } from './cap';

export const camel = (...[head, ...rest]: string[]): string =>
  rest.reduce<string>((previous, part) => `${previous}${cap(part)}`, head);
