import * as yup from 'yup';

import { yupGetNotOneOf } from '../../../lib/yupCommons';

const buildUserNameSchema = (
  skip: null | string,
  users: APIUserOverviewList,
) => {
  let filterBy: ((user: APIUserOverview) => boolean) | undefined;

  if (skip) {
    filterBy = (user) => user.userUUID !== skip;
  }

  const names = yupGetNotOneOf<APIUserOverview>(
    users,
    (user) => user.userName,
    { filterBy },
  );

  return yup.string().notOneOf(names, '${path} already exists');
};

export default buildUserNameSchema;
