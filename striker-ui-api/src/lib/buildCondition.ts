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
  }) as string;

export const buildUnknownIDCondition = (
  keys: unknown,
  conditionPrefix: string,
  { onFallback }: { onFallback?: () => string },
): { after: string; before: string[] } => {
  const before = sanitize(keys, {
    modifierType: 'sql',
    returnType: 'string[]',
  });
  const after = buildIDCondition(before, conditionPrefix, { onFallback });

  return { after, before };
};

export const buildKnownIDCondition = (
  keys: string[] | '*' = '*',
  conditionPrefix: string,
) => (keys[0] === '*' ? '' : buildIDCondition(keys, conditionPrefix));
