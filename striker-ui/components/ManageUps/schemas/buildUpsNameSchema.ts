import * as yup from 'yup';

import { yupGetNotOneOf } from '../../../lib/yupCommons';

const buildUpsNameSchema = (skip: null | string, upses: APIUpsOverviewList) => {
  let filterBy: ((ups: APIUpsOverview) => boolean) | undefined;

  if (skip) {
    filterBy = (ups) => ups.upsUUID !== skip;
  }

  const names = yupGetNotOneOf<APIUpsOverview>(upses, (ups) => ups.upsName, {
    filterBy,
  });

  return yup.string().notOneOf(names, '${path} already exists');
};

export default buildUpsNameSchema;
