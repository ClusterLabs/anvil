import join from './join';
import { sanitizeQS } from './sanitizeQS';

export const buildIDCondition = (
  ids: unknown,
  field: string,
  { onFallback = () => '' }: { onFallback?: () => string },
): { after: string; before: string[] } => {
  const before = sanitizeQS(ids, { isForSQL: true, returnType: 'string[]' });
  const after = join(before, {
    beforeReturn: (toReturn) =>
      toReturn ? `${field} IN (${toReturn})` : onFallback.call(null),
    elementWrapper: "'",
    separator: ', ',
  }) as string;

  return { after, before };
};
