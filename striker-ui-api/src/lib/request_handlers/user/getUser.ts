import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getUser = buildGetRequestHandler((request, buildQueryOptions) => {
  const { user: { uuid: sessionUserUuid } = {} } = request;

  const query = `
    SELECT
      a.user_name,
      a.user_uuid
    FROM users AS a;`;
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
