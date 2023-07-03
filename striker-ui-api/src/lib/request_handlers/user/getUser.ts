import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getUser = buildGetRequestHandler((request, buildQueryOptions) => {
  const { user: { name: sessionUserName, uuid: sessionUserUuid } = {} } =
    request;

  let condLimitRegular = '';

  if (sessionUserName !== 'admin') {
    condLimitRegular = `AND user_uuid = '${sessionUserUuid}'`;
  }

  const query = `
    SELECT
      a.user_name,
      a.user_uuid
    FROM users AS a
    WHERE a.user_algorithm != '${DELETED}'
    ${condLimitRegular};`;

  const afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<
      Record<string, { userName: string; userUUID: string }>
    >((previous, [userName, userUuid]) => {
      const key = userUuid === sessionUserUuid ? 'current' : userUuid;

      previous[key] = {
        userName,
        userUUID: userUuid,
      };

      return previous;
    }, {});

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = afterQueryReturn;
  }

  return query;
});
