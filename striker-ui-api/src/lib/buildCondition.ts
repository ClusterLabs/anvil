import join from './join';
import { sanitizeQS } from './sanitizeQS';

const buildIDCondition = (
  ids: Parameters<JoinFunction>[0],
  conditionPrefix: string,
  {
    onFallback = () => '',
    beforeReturn = (result) =>
      result ? `${conditionPrefix} IN (${result})` : onFallback(),
  }: Pick<JoinOptions, 'beforeReturn'> & { onFallback?: () => string } = {},
) =>
  join(ids, {
    beforeReturn,
    elementWrapper: "'",
    separator: ', ',
  }) as string;

export const buildQSIDCondition = (
  ids: unknown,
  conditionPrefix: string,
  { onFallback = () => '' }: { onFallback?: () => string },
): { after: string; before: string[] } => {
  const before = sanitizeQS(ids, { isForSQL: true, returnType: 'string[]' });
  const after = buildIDCondition(before, conditionPrefix, { onFallback });

  return { after, before };
};

export const buildParamIDCondition = (
  ids: string[] | '*' = '*',
  conditionPrefix: string,
) => (ids[0] === '*' ? '' : buildIDCondition(ids, conditionPrefix));
