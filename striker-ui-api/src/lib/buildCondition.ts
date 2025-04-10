import call from './call';
import join from './join';
import { sanitize } from './sanitize';

const buildIDCondition = (
  keys: Parameters<JoinFunction>[0],
  conditionPrefix: string,
  {
    onFallback,
    beforeReturn = (result) =>
      result
        ? `${conditionPrefix} IN (${result})`
        : call(onFallback, { notCallableReturn: '' }),
  }: Pick<JoinOptions, 'beforeReturn'> & { onFallback?: () => string } = {},
) =>
  join(keys, {
    beforeReturn,
    elementWrapper: "'",
    separator: ', ',
  });

export const buildUnknownIDCondition = (
  keys: unknown,
  conditionPrefix: string,
  { onFallback }: { onFallback?: () => string } = {},
): { after: string; before: string[] } => {
  const before = sanitize(keys, 'string[]', {
    modifierType: 'sql',
  });
  const after = buildIDCondition(before, conditionPrefix, { onFallback });

  return { after, before };
};

export const buildKnownIDCondition = (
  keys: string[] | 'all' | '*' = 'all',
  conditionPrefix: string,
) =>
  !(keys instanceof Array) || keys.some((v) => ['all', '*'].includes(v))
    ? ''
    : buildIDCondition(keys, conditionPrefix);
