import { NextRouter } from 'next/router';

const setQueryParam = (
  router: NextRouter,
  key: string,
  value?: string,
): typeof router.query => {
  const { query: previous } = router;

  let query;

  // No value means removing the param
  if (value === undefined) {
    const { [key]: rm, ...rest } = previous;

    query = rest;
  } else {
    query = { ...previous, [key]: value };
  }

  return query;
};

export default setQueryParam;
