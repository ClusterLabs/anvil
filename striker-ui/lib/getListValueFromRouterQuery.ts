import { NextRouter } from 'next/router';

import getQueryParam from './getQueryParam';

const getListValueFromRouterQuery = <T>(
  list: Record<string, T> | undefined,
  router: NextRouter,
  predicate: (name: string) => (value: T) => boolean,
): T | undefined => {
  if (!list || !router.isReady) {
    return undefined;
  }

  let result: T | undefined;

  const { name, uuid } = router.query;

  if (name) {
    result = Object.values(list).find(predicate(getQueryParam(name)));
  } else if (uuid) {
    const key = getQueryParam(uuid);

    result = list[key];
  }

  return result;
};

export default getListValueFromRouterQuery;
