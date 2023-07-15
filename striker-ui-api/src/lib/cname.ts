import { COOKIE_PREFIX } from './consts';

export const cname = (postfix: string) => `${COOKIE_PREFIX}.${postfix}`;
