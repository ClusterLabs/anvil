import join from './join';
import { sanitizeQS } from './sanitizeQS';

export const buildIDCondition = (
  ids: unknown,
  field: string,
  { onFallback = () => '' }: { onFallback?: () => string },
): string =>
  join(sanitizeQS(ids, { returnType: 'string[]' }), {
    beforeReturn: (toReturn) =>
      toReturn ? `${field} IN (${toReturn})` : onFallback.call(null),
    elementWrapper: "'",
    separator: ', ',
  }) as string;
